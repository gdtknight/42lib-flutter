// US3: BookSuggestion service — student-submitted book recommendations,
// scoped to an active collection period.
// Reference: data-model.md Entity 6 (BookSuggestion), Entity 7 (CollectionPeriod)

import {
  PrismaClient,
  PeriodStatus,
  SuggestionStatus,
} from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export class SuggestionError extends Error {
  constructor(
    public code:
      | 'no_active_period'
      | 'duplicate_suggestion'
      | 'period_not_found',
    message: string,
  ) {
    super(message);
    this.name = 'SuggestionError';
  }
}

export class SuggestionService {
  async getActivePeriod() {
    return prisma.collectionPeriod.findFirst({
      where: { status: PeriodStatus.active },
      orderBy: { startDate: 'desc' },
    });
  }

  /**
   * T168/T171: Submit a new suggestion. Must fall within the currently
   * active collection period. Dedupes per (student, title, author, period).
   */
  async createSuggestion(
    studentId: string,
    payload: {
      suggestedTitle: string;
      suggestedAuthor: string;
      reason?: string;
    },
  ) {
    const period = await this.getActivePeriod();
    if (!period) {
      throw new SuggestionError(
        'no_active_period',
        '현재 활성 수집 기간이 없습니다.',
      );
    }

    const trimmedTitle = payload.suggestedTitle.trim();
    const trimmedAuthor = payload.suggestedAuthor.trim();

    const existing = await prisma.bookSuggestion.findFirst({
      where: {
        studentId,
        collectionPeriodId: period.id,
        suggestedTitle: trimmedTitle,
        suggestedAuthor: trimmedAuthor,
      },
    });
    if (existing) {
      throw new SuggestionError(
        'duplicate_suggestion',
        '동일한 도서를 이미 추천했습니다.',
      );
    }

    const suggestion = await prisma.bookSuggestion.create({
      data: {
        studentId,
        suggestedTitle: trimmedTitle,
        suggestedAuthor: trimmedAuthor,
        reason: payload.reason?.trim() || null,
        collectionPeriodId: period.id,
        status: SuggestionStatus.submitted,
      },
      include: {
        collectionPeriod: { select: { id: true, name: true, endDate: true } },
      },
    });

    logger.info('Book suggestion submitted', {
      studentId,
      suggestionId: suggestion.id,
      periodId: period.id,
    });
    return suggestion;
  }

  /**
   * T169: Student's own suggestions across all periods.
   */
  async getStudentSuggestions(studentId: string) {
    return prisma.bookSuggestion.findMany({
      where: { studentId },
      orderBy: { submittedAt: 'desc' },
      include: {
        collectionPeriod: {
          select: { id: true, name: true, status: true, endDate: true },
        },
      },
    });
  }
}

export const suggestionService = new SuggestionService();
