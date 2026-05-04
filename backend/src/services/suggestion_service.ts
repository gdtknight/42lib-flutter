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
      | 'period_not_found'
      | 'suggestion_not_found'
      | 'invalid_status',
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

  /**
   * T184/T187: Admin grouped list — same title+author within a period
   * collapsed into a single entry with requesterCount and per-status counts.
   * Optional `periodId` filter; default = active period; if no active period
   * and no filter, returns all.
   */
  async getGroupedSuggestions(filter: { periodId?: string } = {}) {
    let periodId = filter.periodId;
    if (!periodId) {
      const active = await this.getActivePeriod();
      periodId = active?.id;
    }

    const where = periodId ? { collectionPeriodId: periodId } : {};
    const items = await prisma.bookSuggestion.findMany({
      where,
      orderBy: { submittedAt: 'desc' },
      include: {
        student: { select: { id: true, username: true, fullName: true } },
        collectionPeriod: { select: { id: true, name: true, status: true, endDate: true } },
      },
    });

    // Group in memory — small N (per-period dataset).
    const groups = new Map<
      string,
      {
        suggestedTitle: string;
        suggestedAuthor: string;
        collectionPeriodId: string;
        requesterCount: number;
        statuses: Record<string, number>;
        latestSubmittedAt: Date;
        items: typeof items;
      }
    >();

    for (const s of items) {
      const key = `${s.suggestedTitle}::${s.suggestedAuthor}::${s.collectionPeriodId}`;
      const existing = groups.get(key);
      if (existing) {
        existing.requesterCount++;
        existing.statuses[s.status] = (existing.statuses[s.status] ?? 0) + 1;
        existing.items.push(s);
        if (s.submittedAt > existing.latestSubmittedAt) {
          existing.latestSubmittedAt = s.submittedAt;
        }
      } else {
        groups.set(key, {
          suggestedTitle: s.suggestedTitle,
          suggestedAuthor: s.suggestedAuthor,
          collectionPeriodId: s.collectionPeriodId,
          requesterCount: 1,
          statuses: { [s.status]: 1 },
          latestSubmittedAt: s.submittedAt,
          items: [s],
        });
      }
    }

    return Array.from(groups.values()).sort(
      (a, b) => b.requesterCount - a.requesterCount,
    );
  }

  /**
   * T185: Admin marks a suggestion as approved/rejected/under_review.
   * `adminNotes` is optional context shown to the student.
   */
  async reviewSuggestion(
    suggestionId: string,
    adminId: string,
    payload: { status: SuggestionStatus; adminNotes?: string },
  ) {
    const existing = await prisma.bookSuggestion.findUnique({
      where: { id: suggestionId },
    });
    if (!existing) {
      throw new SuggestionError(
        'suggestion_not_found',
        '제안을 찾을 수 없습니다.',
      );
    }

    const updated = await prisma.bookSuggestion.update({
      where: { id: suggestionId },
      data: {
        status: payload.status,
        reviewedAt: new Date(),
        reviewedBy: adminId,
        adminNotes: payload.adminNotes?.trim() || existing.adminNotes,
      },
      include: {
        student: { select: { id: true, username: true, fullName: true } },
      },
    });

    logger.info('Suggestion reviewed', {
      suggestionId,
      status: payload.status,
      adminId,
    });
    return updated;
  }

  /**
   * T186/T188: Admin creates a CollectionPeriod. If new period is `active`,
   * any pre-existing active period is archived to `closed` (only one active
   * at a time).
   */
  async createPeriod(payload: {
    name: string;
    startDate: Date;
    endDate: Date;
    status?: PeriodStatus;
  }) {
    const status = payload.status ?? PeriodStatus.upcoming;

    return prisma.$transaction(async (tx) => {
      if (status === PeriodStatus.active) {
        await tx.collectionPeriod.updateMany({
          where: { status: PeriodStatus.active },
          data: { status: PeriodStatus.closed },
        });
      }

      const period = await tx.collectionPeriod.create({
        data: {
          name: payload.name.trim(),
          startDate: payload.startDate,
          endDate: payload.endDate,
          status,
        },
      });

      logger.info('Collection period created', { periodId: period.id, status });
      return period;
    });
  }
}

export const suggestionService = new SuggestionService();
