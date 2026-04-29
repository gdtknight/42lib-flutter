// T107: 42 OAuth 2.0 Authentication Service
// Implements OAuth flow with 42 API for student authentication
// Reference: research.md Section 3 (42 API Integration)

import axios from 'axios';
import { PrismaClient } from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

interface FortyTwoUser {
  id: number;
  login: string;
  email: string;
  displayname: string;
  usual_full_name: string;
}

interface TokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  refresh_token: string;
  scope: string;
  created_at: number;
}

export class Auth42Service {
  private clientId: string;
  private clientSecret: string;
  private redirectUri: string;
  private authorizationUrl = 'https://api.intra.42.fr/oauth/authorize';
  private tokenUrl = 'https://api.intra.42.fr/oauth/token';
  private userInfoUrl = 'https://api.intra.42.fr/v2/me';

  constructor() {
    this.clientId = process.env.FORTYTWO_CLIENT_ID || '';
    this.clientSecret = process.env.FORTYTWO_CLIENT_SECRET || '';
    this.redirectUri = process.env.FORTYTWO_REDIRECT_URI || '';

    // Don't throw at construction — let MVP/admin flows boot without 42 creds.
    // Only the OAuth-using methods reject when creds are missing.
    if (!this.clientId || !this.clientSecret || !this.redirectUri) {
      logger.warn(
        '42 OAuth credentials not configured. Student OAuth flows will be unavailable.',
      );
    }
  }

  private requireConfigured(): void {
    if (!this.clientId || !this.clientSecret || !this.redirectUri) {
      throw new Error('42 OAuth configuration missing');
    }
  }

  /**
   * Generate authorization URL for OAuth flow
   */
  getAuthorizationUrl(state?: string): string {
    this.requireConfigured();
    const params = new URLSearchParams({
      client_id: this.clientId,
      redirect_uri: this.redirectUri,
      response_type: 'code',
      scope: 'public',
      state: state || Math.random().toString(36).substring(7),
    });

    return `${this.authorizationUrl}?${params.toString()}`;
  }

  /**
   * Exchange authorization code for access token
   */
  async exchangeCodeForToken(code: string): Promise<TokenResponse> {
    this.requireConfigured();
    try {
      const response = await axios.post<TokenResponse>(
        this.tokenUrl,
        {
          grant_type: 'authorization_code',
          client_id: this.clientId,
          client_secret: this.clientSecret,
          code,
          redirect_uri: this.redirectUri,
        },
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        }
      );

      logger.info('Successfully exchanged code for 42 access token');
      return response.data;
    } catch (error: any) {
      logger.error('Failed to exchange code for token', {
        error: error.response?.data || error.message,
      });
      throw new Error('42 OAuth token exchange failed');
    }
  }

  /**
   * Fetch user information from 42 API
   */
  async getUserInfo(accessToken: string): Promise<FortyTwoUser> {
    try {
      const response = await axios.get<FortyTwoUser>(this.userInfoUrl, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      });

      logger.info('Successfully fetched 42 user info', {
        userId: response.data.id,
        login: response.data.login,
      });

      return response.data;
    } catch (error: any) {
      logger.error('Failed to fetch 42 user info', {
        error: error.response?.data || error.message,
      });
      throw new Error('42 API user info fetch failed');
    }
  }

  /**
   * Find or create student in database from 42 user data
   * BR-102: Student account created automatically on first login
   * BR-103: Student data refreshed from 42 API on each login
   */
  async findOrCreateStudent(fortyTwoUser: FortyTwoUser) {
    try {
      // Try to find existing student
      let student = await prisma.student.findUnique({
        where: { fortytwoUserId: fortyTwoUser.id },
      });

      if (student) {
        // Update existing student data (BR-103)
        student = await prisma.student.update({
          where: { id: student.id },
          data: {
            username: fortyTwoUser.login,
            email: fortyTwoUser.email,
            fullName: fortyTwoUser.usual_full_name || fortyTwoUser.displayname,
            lastLoginAt: new Date(),
          },
        });

        logger.info('Updated existing student', {
          studentId: student.id,
          fortytwoUserId: fortyTwoUser.id,
        });
      } else {
        // Create new student (BR-102)
        student = await prisma.student.create({
          data: {
            fortytwoUserId: fortyTwoUser.id,
            username: fortyTwoUser.login,
            email: fortyTwoUser.email,
            fullName: fortyTwoUser.usual_full_name || fortyTwoUser.displayname,
          },
        });

        logger.info('Created new student', {
          studentId: student.id,
          fortytwoUserId: fortyTwoUser.id,
        });
      }

      return student;
    } catch (error: any) {
      logger.error('Failed to find or create student', { error: error.message });
      throw new Error('Student database operation failed');
    }
  }

  /**
   * Complete OAuth flow: exchange code, fetch user, create/update student
   */
  async authenticateWithCode(code: string) {
    // Step 1: Exchange code for access token
    const tokenResponse = await this.exchangeCodeForToken(code);

    // Step 2: Fetch user info from 42 API
    const fortyTwoUser = await this.getUserInfo(tokenResponse.access_token);

    // Step 3: Find or create student in database
    const student = await this.findOrCreateStudent(fortyTwoUser);

    return {
      student,
      accessToken: tokenResponse.access_token,
      expiresIn: tokenResponse.expires_in,
    };
  }
}

export const auth42Service = new Auth42Service();
