#!/usr/bin/env bash
set -euo pipefail

echo "🎄 Создаю структуру проекта Адвент-календаря..."

mkdir -p shared
mkdir -p server/config server/db server/services server/middleware server/routes server/bot server/tests
mkdir -p client/src/api client/src/components client/src/pages

cat << '__END_OF_FILE__' > package.json
{
  "name": "telegram-advent-calendar",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "NODE_ENV=development tsx server/index.ts",
    "build": "vite build && esbuild server/index.ts --bundle --platform=node --packages=external --format=esm --outfile=dist/server.js",
    "start": "NODE_ENV=production node dist/server.js",
    "db:migrate": "tsx server/db/cli.ts migrate",
    "db:seed": "tsx server/db/cli.ts seed",
    "test": "tsx --test server/tests/app.test.ts",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@twa-dev/sdk": "^7.10.0",
    "express": "^4.21.1",
    "grammy": "^1.31.0",
    "lucide-react": "^0.454.0",
    "pg": "^8.13.1",
    "zod": "^3.23.8"
  },
  "devDependencies": {
    "@types/express": "^5.0.0",
    "@types/node": "^22.9.0",
    "@types/pg": "^8.11.10",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.12",
    "@vitejs/plugin-react": "^4.3.3",
    "autoprefixer": "^10.4.20",
    "esbuild": "^0.24.0",
    "postcss": "^8.4.47",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "tailwindcss": "^3.4.14",
    "tsx": "^4.19.2",
    "typescript": "^5.6.3",
    "vite": "^5.4.10"
  }
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > .replit
run = "npm run start"
entrypoint = "server/index.ts"

[nix]
channel = "stable-24_05"

[deployment]
build = ["npm", "run", "build"]
run = ["npm", "run", "start"]
deploymentTarget = "vm"
__END_OF_FILE__

cat << '__END_OF_FILE__' > .env.example
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/advent
TELEGRAM_BOT_TOKEN=123456789:replace-with-real-bot-token
ADMIN_TELEGRAM_ID=123456789
ADMIN_USERNAME=your_admin_username
MINI_APP_URL=https://your-app.replit.app
BOT_USERNAME=your_bot_username

# Опционально:
BOT_MODE=polling
TELEGRAM_WEBHOOK_SECRET=replace-with-random-secret
CRON_SECRET=replace-with-random-cron-secret
SESSION_SECRET=replace-with-random-session-secret
STRICT_PAID_DRIP=false
PORT=5000
__END_OF_FILE__

cat << '__END_OF_FILE__' > tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "noEmit": true,
    "baseUrl": ".",
    "paths": {
      "@shared/*": ["shared/*"]
    }
  },
  "include": ["client/src", "server", "shared", "vite.config.ts"]
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  plugins: [react()],
  root: path.resolve(__dirname, 'client'),
  resolve: {
    alias: {
      '@shared': path.resolve(__dirname, 'shared'),
    },
  },
  build: {
    outDir: path.resolve(__dirname, 'dist/client'),
    emptyOutDir: true,
  },
});
__END_OF_FILE__

cat << '__END_OF_FILE__' > tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./client/index.html', './client/src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        pine: {
          950: '#081813',
          900: '#0F2A22',
          800: '#163B30',
          700: '#1F5142',
        },
        ivory: {
          50: '#FCF9F2',
          100: '#F6EFE2',
          200: '#EADCC5',
        },
        gold: {
          400: '#E2BA6B',
          500: '#D4A853',
          600: '#B68934',
        },
        berry: {
          600: '#9E332B',
          700: '#7D2620',
        },
      },
    },
  },
  plugins: [],
};
__END_OF_FILE__

cat << '__END_OF_FILE__' > postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
__END_OF_FILE__

cat << '__END_OF_FILE__' > shared/types.ts
export type PaymentStatus = 'unpaid' | 'paid';
export type AccessStatus = 'free' | 'expired' | 'full';

export type DayCardState =
  | 'available'
  | 'completed'
  | 'locked_time'
  | 'locked_payment';

export interface DayContent {
  mainText: string;
  images?: { url: string; caption?: string }[];
  videos?: { title: string; url: string; embedUrl?: string }[];
  audios?: { title: string; url: string }[];
  links?: { label: string; url: string }[];
  task?: { title: string; description: string };
  downloads?: { label: string; url: string; fileSize?: string }[];
}

export interface CalendarDaySummary {
  id: number;
  title: string;
  description: string;
  state: DayCardState;
  completed: boolean;
  completedAt: string | null;
  unlocksAt: string | null;
}

export interface UserAccessSummary {
  telegramId: string;
  telegramUsername: string | null;
  firstName: string;
  registrationDate: string;
  freePeriodEnd: string;
  paymentStatus: PaymentStatus;
  accessStatus: AccessStatus;
  isFreePeriodActive: boolean;
  currentTimelineDay: number;
  completedCount: number;
  totalDays: number;
  nextDayId: number | null;
  nextDayUnlocksAt: string | null;
  adminUsername: string;
}

export interface CalendarResponse {
  user: UserAccessSummary;
  days: CalendarDaySummary[];
}

export interface DayDetailResponse {
  day: {
    id: number;
    title: string;
    description: string;
    content: DayContent;
    completed: boolean;
    completedAt: string | null;
  };
  user: UserAccessSummary;
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/config/env.ts
import { z } from 'zod';
import crypto from 'crypto';

const envSchema = z.object({
  DATABASE_URL: z.string().min(1, 'Не задана переменная DATABASE_URL'),
  TELEGRAM_BOT_TOKEN: z.string().min(10, 'Не задана переменная TELEGRAM_BOT_TOKEN'),
  ADMIN_TELEGRAM_ID: z.string().regex(/^\d+$/, 'ADMIN_TELEGRAM_ID должен быть числовым Telegram ID'),
  ADMIN_USERNAME: z.string().min(1, 'Не задана переменная ADMIN_USERNAME'),
  MINI_APP_URL: z.string().url('MINI_APP_URL должен быть корректным URL'),
  BOT_USERNAME: z.string().optional().default(''),
  BOT_MODE: z.enum(['polling', 'webhook']).optional().default('polling'),
  TELEGRAM_WEBHOOK_SECRET: z.string().optional(),
  CRON_SECRET: z.string().optional(),
  SESSION_SECRET: z.string().optional(),
  STRICT_PAID_DRIP: z
    .string()
    .optional()
    .transform((v) => v === 'true'),
  PORT: z.coerce.number().int().positive().optional().default(5000),
  NODE_ENV: z.string().optional().default('development'),
});

export type AppEnv = Omit<z.infer<typeof envSchema>, 'ADMIN_USERNAME' | 'BOT_USERNAME'> & {
  ADMIN_USERNAME: string;
  BOT_USERNAME: string;
  SESSION_SECRET: string;
  TELEGRAM_WEBHOOK_SECRET: string;
  CRON_SECRET: string;
};

let cachedEnv: AppEnv | null = null;

export function getEnv(): AppEnv {
  if (cachedEnv) return cachedEnv;

  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    console.error('❌ Ошибка конфигурации переменных окружения:');
    for (const issue of parsed.error.issues) {
      console.error(`   - ${issue.path.join('.')}: ${issue.message}`);
    }
    console.error('ℹ️ Проверьте Replit Secrets или файл .env (см. .env.example).');
    process.exit(1);
  }

  const data = parsed.data;
  const fallbackSecret = crypto
    .createHmac('sha256', 'advent-derived-secret')
    .update(data.TELEGRAM_BOT_TOKEN)
    .digest('hex');

  cachedEnv = {
    ...data,
    ADMIN_USERNAME: data.ADMIN_USERNAME.replace(/^@/, ''),
    BOT_USERNAME: data.BOT_USERNAME.replace(/^@/, ''),
    SESSION_SECRET: data.SESSION_SECRET || fallbackSecret,
    TELEGRAM_WEBHOOK_SECRET: data.TELEGRAM_WEBHOOK_SECRET || fallbackSecret.slice(0, 32),
    CRON_SECRET: data.CRON_SECRET || fallbackSecret.slice(32, 64),
  };

  return cachedEnv;
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/db/pool.ts
import { Pool } from 'pg';
import { getEnv } from '../config/env';

let pool: Pool | null = null;

export function getPool(): Pool {
  if (pool) return pool;
  const env = getEnv();
  const useSsl =
    env.DATABASE_URL.includes('sslmode=require') || process.env.PGSSLMODE === 'require';

  pool = new Pool({
    connectionString: env.DATABASE_URL,
    ssl: useSsl ? { rejectUnauthorized: false } : undefined,
    max: 10,
  });

  pool.on('error', (err) => {
    console.error('Ошибка пула PostgreSQL:', err);
  });

  return pool;
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/db/migrate.ts
import { Pool } from 'pg';

export async function runMigrations(pool: Pool): Promise<void> {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      telegram_id BIGINT NOT NULL UNIQUE,
      telegram_username TEXT,
      first_name TEXT NOT NULL DEFAULT 'Гость',
      registration_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      free_period_end TIMESTAMPTZ NOT NULL,
      payment_status TEXT NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid')),
      access_status TEXT NOT NULL DEFAULT 'free' CHECK (access_status IN ('free', 'expired', 'full')),
      payment_confirmed_at TIMESTAMPTZ,
      payment_confirmed_by BIGINT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_users_payment_free_end
      ON users (payment_status, free_period_end);

    CREATE TABLE IF NOT EXISTS advent_days (
      id INTEGER PRIMARY KEY CHECK (id BETWEEN 1 AND 25),
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      content JSONB NOT NULL,
      is_published BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS user_progress (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      day_id INTEGER NOT NULL REFERENCES advent_days(id) ON DELETE CASCADE,
      completed BOOLEAN NOT NULL DEFAULT TRUE,
      completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (user_id, day_id)
    );

    CREATE INDEX IF NOT EXISTS idx_user_progress_user_id
      ON user_progress (user_id);

    CREATE TABLE IF NOT EXISTS notification_log (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      notification_type TEXT NOT NULL CHECK (notification_type IN ('free_period_ended', 'payment_confirmed')),
      sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'failed')),
      error_message TEXT,
      UNIQUE (user_id, notification_type)
    );

    CREATE TABLE IF NOT EXISTS admin_audit_log (
      id SERIAL PRIMARY KEY,
      admin_telegram_id BIGINT NOT NULL,
      target_user_telegram_id BIGINT NOT NULL,
      action TEXT NOT NULL,
      details TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at
      ON admin_audit_log (created_at DESC);
  `);
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/db/seed.ts
import { Pool } from 'pg';
import type { DayContent } from '../../shared/types';

function buildPlaceholderDay(day: number): {
  id: number;
  title: string;
  description: string;
  content: DayContent;
} {
  const isFree = day <= 7;
  const tierLabel = isFree ? 'Бесплатный период' : 'Основная программа';

  const content: DayContent = {
    mainText: [
      `[ЗАГЛУШКА ДНЯ ${day}] Это демонстрационный текст для ${day}-го дня адвент-календаря (${tierLabel}).`,
      `Здесь размещается основная история, письмо дня, практика осознанности или вдохновляющая заметка. Вы можете легко заменить этот текст прямо в таблице advent_days базы данных без пересборки приложения.`,
    ].join('\n\n'),
    images:
      day % 2 === 1
        ? [
            {
              url: `https://placehold.co/800x450/0F2A22/E2BA6B?text=Advent+Day+${day}`,
              caption: `[ЗАГЛУШКА] Иллюстрация к дню ${day}`,
            },
          ]
        : undefined,
    videos:
      day % 3 === 1
        ? [
            {
              title: `[ЗАГЛУШКА] Видеообращение или урок дня ${day}`,
              url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            },
          ]
        : undefined,
    audios:
      day % 2 === 0
        ? [
            {
              title: `[ЗАГЛУШКА] Аудиопрактика / подкаст дня ${day}`,
              url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            },
          ]
        : undefined,
    task: {
      title: `Задание дня ${day}`,
      description: `[ЗАГЛУШКА ЗАДАНИЯ ${day}] Выделите 10 минут для себя, выполните упражнение дня и запишите главное наблюдение, затем отметьте день как пройденный.`,
    },
    links: [
      {
        label: `[ЗАГЛУШКА] Полезный материал к дню ${day}`,
        url: 'https://telegram.org',
      },
    ],
    downloads:
      day % 5 === 0
        ? [
            {
              label: `[ЗАГЛУШКА] Рабочая тетрадь / чек-лист дня ${day} (PDF)`,
              url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
              fileSize: 'PDF • пример',
            },
          ]
        : undefined,
  };

  return {
    id: day,
    title: `[ЗАГЛУШКА ДНЯ ${day}] Тема ${day}-го дня адвента`,
    description: `[ЗАГЛУШКА] Краткое описание материала и задания для дня ${day}.`,
    content,
  };
}

export async function seedAdventDays(pool: Pool): Promise<void> {
  const { rows } = await pool.query<{ count: string }>('SELECT COUNT(*) AS count FROM advent_days');
  if (Number(rows[0]?.count ?? 0) >= 25) {
    return;
  }

  for (let day = 1; day <= 25; day++) {
    const item = buildPlaceholderDay(day);
    await pool.query(
      `
      INSERT INTO advent_days (id, title, description, content, is_published)
      VALUES ($1, $2, $3, $4::jsonb, TRUE)
      ON CONFLICT (id) DO NOTHING
      `,
      [item.id, item.title, item.description, JSON.stringify(item.content)]
    );
  }
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/db/cli.ts
import { getPool } from './pool';
import { runMigrations } from './migrate';
import { seedAdventDays } from './seed';

async function main() {
  const command = process.argv[2];
  const pool = getPool();

  try {
    if (command === 'migrate') {
      await runMigrations(pool);
      console.log('✅ Миграции успешно выполнены.');
    } else if (command === 'seed') {
      await runMigrations(pool);
      await seedAdventDays(pool);
      console.log('✅ 25 тестовых дней адвента добавлены (если отсутствовали).');
    } else {
      console.log('Использование: tsx server/db/cli.ts [migrate|seed]');
      process.exitCode = 1;
    }
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('❌ Ошибка БД CLI:', err);
  process.exit(1);
});
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/services/telegramAuth.ts
import crypto from 'crypto';

export interface VerifiedTelegramUser {
  telegramId: string;
  username: string | null;
  firstName: string;
}

export interface SessionPayload {
  userId: number;
  telegramId: string;
  exp: number;
}

export function verifyTelegramInitData(
  initData: string,
  botToken: string,
  maxAgeSeconds = 86400
): VerifiedTelegramUser | null {
  if (!initData || typeof initData !== 'string') return null;

  const params = new URLSearchParams(initData);
  const hash = params.get('hash');
  if (!hash) return null;

  params.delete('hash');
  const dataCheckString = Array.from(params.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([key, value]) => `${key}=${value}`)
    .join('\n');

  const secretKey = crypto.createHmac('sha256', 'WebAppData').update(botToken).digest();
  const expectedHex = crypto.createHmac('sha256', secretKey).update(dataCheckString).digest('hex');

  const hashBuffer = Buffer.from(hash, 'hex');
  const expectedBuffer = Buffer.from(expectedHex, 'hex');
  if (hashBuffer.length === 0 || hashBuffer.length !== expectedBuffer.length) {
    return null;
  }
  if (!crypto.timingSafeEqual(hashBuffer, expectedBuffer)) {
    return null;
  }

  const authDate = Number(params.get('auth_date'));
  const nowSec = Math.floor(Date.now() / 1000);
  if (!Number.isFinite(authDate) || nowSec - authDate > maxAgeSeconds) {
    return null;
  }

  const rawUser = params.get('user');
  if (!rawUser) return null;

  try {
    const parsedUser = JSON.parse(rawUser) as {
      id?: number | string;
      username?: string;
      first_name?: string;
    };
    if (!parsedUser?.id) return null;

    return {
      telegramId: String(parsedUser.id),
      username: parsedUser.username || null,
      firstName: parsedUser.first_name?.trim() || 'Участник',
    };
  } catch {
    return null;
  }
}

export function signSessionToken(
  payload: Omit<SessionPayload, 'exp'>,
  secret: string,
  ttlSeconds = 60 * 60 * 12
): string {
  const fullPayload: SessionPayload = {
    ...payload,
    exp: Math.floor(Date.now() / 1000) + ttlSeconds,
  };
  const encoded = Buffer.from(JSON.stringify(fullPayload)).toString('base64url');
  const signature = crypto.createHmac('sha256', secret).update(encoded).digest('base64url');
  return `${encoded}.${signature}`;
}

export function verifySessionToken(token: string, secret: string): SessionPayload | null {
  if (!token || !token.includes('.')) return null;
  const [encoded, signature] = token.split('.');
  if (!encoded || !signature) return null;

  const expectedSig = crypto.createHmac('sha256', secret).update(encoded).digest('base64url');
  const sigBuf = Buffer.from(signature);
  const expBuf = Buffer.from(expectedSig);
  if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
    return null;
  }

  try {
    const parsed = JSON.parse(Buffer.from(encoded, 'base64url').toString('utf8')) as SessionPayload;
    if (!parsed.userId || !parsed.telegramId || !parsed.exp) return null;
    if (Math.floor(Date.now() / 1000) > parsed.exp) return null;
    return parsed;
  } catch {
    return null;
  }
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/services/access.ts
import type { Pool } from 'pg';
import type {
  AccessStatus,
  CalendarDaySummary,
  DayCardState,
  DayContent,
  PaymentStatus,
  UserAccessSummary,
} from '../../shared/types';
import type { VerifiedTelegramUser } from './telegramAuth';

const MS_PER_HOUR = 60 * 60 * 1000;
const MS_PER_DAY = 24 * MS_PER_HOUR;
const FREE_HOURS = 168;

export interface UserRow {
  id: number;
  telegram_id: string;
  telegram_username: string | null;
  first_name: string;
  registration_date: Date;
  free_period_end: Date;
  payment_status: PaymentStatus;
  access_status: AccessStatus;
  payment_confirmed_at: Date | null;
  payment_confirmed_by: string | null;
}

export async function upsertUserOnLaunch(
  pool: Pool,
  tgUser: VerifiedTelegramUser
): Promise<UserRow> {
  const { rows } = await pool.query<UserRow>(
    `
    INSERT INTO users (
      telegram_id,
      telegram_username,
      first_name,
      registration_date,
      free_period_end,
      payment_status,
      access_status
    )
    VALUES ($1, $2, $3, NOW(), NOW() + ($4::int * INTERVAL '1 hour'), 'unpaid', 'free')
    ON CONFLICT (telegram_id) DO UPDATE SET
      telegram_username = EXCLUDED.telegram_username,
      first_name = EXCLUDED.first_name,
      updated_at = NOW()
    RETURNING
      id,
      telegram_id::text AS telegram_id,
      telegram_username,
      first_name,
      registration_date,
      free_period_end,
      payment_status,
      access_status,
      payment_confirmed_at,
      payment_confirmed_by::text AS payment_confirmed_by
    `,
    [tgUser.telegramId, tgUser.username, tgUser.firstName, FREE_HOURS]
  );

  return rows[0];
}

export async function getUserById(pool: Pool, userId: number): Promise<UserRow | null> {
  const { rows } = await pool.query<UserRow>(
    `
    SELECT
      id,
      telegram_id::text AS telegram_id,
      telegram_username,
      first_name,
      registration_date,
      free_period_end,
      payment_status,
      access_status,
      payment_confirmed_at,
      payment_confirmed_by::text AS payment_confirmed_by
    FROM users
    WHERE id = $1
    `,
    [userId]
  );
  return rows[0] ?? null;
}

export function computeEffectiveAccessStatus(user: UserRow, now: Date): AccessStatus {
  if (user.payment_status === 'paid') return 'full';
  return now.getTime() < user.free_period_end.getTime() ? 'free' : 'expired';
}

export function computeTimelineDay(registrationDate: Date, now: Date): number {
  const elapsedMs = Math.max(0, now.getTime() - registrationDate.getTime());
  return Math.min(25, Math.floor(elapsedMs / MS_PER_DAY) + 1);
}

export function evaluateDayAccess(params: {
  dayId: number;
  user: UserRow;
  now: Date;
  strictPaidDrip: boolean;
}): {
  accessible: boolean;
  reason: 'ok' | 'locked_time' | 'locked_payment';
  unlocksAt: Date | null;
} {
  const { dayId, user, now, strictPaidDrip } = params;
  const currentDay = computeTimelineDay(user.registration_date, now);
  const dayArrivalDate = new Date(user.registration_date.getTime() + (dayId - 1) * MS_PER_DAY);
  const isPaid = user.payment_status === 'paid';

  if (dayId <= 7) {
    if (dayId <= currentDay) {
      return { accessible: true, reason: 'ok', unlocksAt: null };
    }
    return { accessible: false, reason: 'locked_time', unlocksAt: dayArrivalDate };
  }

  if (!isPaid) {
    return { accessible: false, reason: 'locked_payment', unlocksAt: null };
  }

  if (!strictPaidDrip || dayId <= currentDay) {
    return { accessible: true, reason: 'ok', unlocksAt: null };
  }

  return { accessible: false, reason: 'locked_time', unlocksAt: dayArrivalDate };
}

export async function buildCalendarData(params: {
  pool: Pool;
  user: UserRow;
  adminUsername: string;
  strictPaidDrip: boolean;
  now?: Date;
}): Promise<{ user: UserAccessSummary; days: CalendarDaySummary[] }> {
  const { pool, user, adminUsername, strictPaidDrip } = params;
  const now = params.now ?? new Date();

  const effectiveAccessStatus = computeEffectiveAccessStatus(user, now);
  if (effectiveAccessStatus !== user.access_status) {
    await pool.query('UPDATE users SET access_status = $1, updated_at = NOW() WHERE id = $2', [
      effectiveAccessStatus,
      user.id,
    ]);
  }

  const [{ rows: dayRows }, { rows: progressRows }] = await Promise.all([
    pool.query<{ id: number; title: string; description: string }>(
      'SELECT id, title, description FROM advent_days WHERE is_published = TRUE ORDER BY id ASC'
    ),
    pool.query<{ day_id: number; completed: boolean; completed_at: Date }>(
      'SELECT day_id, completed, completed_at FROM user_progress WHERE user_id = $1',
      [user.id]
    ),
  ]);

  const progressMap = new Map<number, { completed: boolean; completedAt: Date }>();
  for (const row of progressRows) {
    if (row.completed) {
      progressMap.set(row.day_id, { completed: true, completedAt: row.completed_at });
    }
  }

  const currentTimelineDay = computeTimelineDay(user.registration_date, now);
  let nextDayId: number | null = null;
  let nextDayUnlocksAt: Date | null = null;

  const days: CalendarDaySummary[] = dayRows.map((d) => {
    const access = evaluateDayAccess({ dayId: d.id, user, now, strictPaidDrip });
    const progress = progressMap.get(d.id);

    let state: DayCardState;
    if (!access.accessible) {
      state = access.reason;
      if (access.reason === 'locked_time' && access.unlocksAt && !nextDayId) {
        nextDayId = d.id;
        nextDayUnlocksAt = access.unlocksAt;
      }
    } else if (progress?.completed) {
      state = 'completed';
    } else {
      state = 'available';
    }

    return {
      id: d.id,
      title: d.title,
      description: d.description,
      state,
      completed: Boolean(progress?.completed),
      completedAt: progress?.completedAt ? progress.completedAt.toISOString() : null,
      unlocksAt: access.unlocksAt ? access.unlocksAt.toISOString() : null,
    };
  });

  const summary: UserAccessSummary = {
    telegramId: user.telegram_id,
    telegramUsername: user.telegram_username,
    firstName: user.first_name,
    registrationDate: user.registration_date.toISOString(),
    freePeriodEnd: user.free_period_end.toISOString(),
    paymentStatus: user.payment_status,
    accessStatus: effectiveAccessStatus,
    isFreePeriodActive: now.getTime() < user.free_period_end.getTime(),
    currentTimelineDay,
    completedCount: progressMap.size,
    totalDays: 25,
    nextDayId,
    nextDayUnlocksAt: nextDayUnlocksAt ? nextDayUnlocksAt.toISOString() : null,
    adminUsername,
  };

  return { user: summary, days };
}

export async function getPublishedDayById(
  pool: Pool,
  dayId: number
): Promise<{ id: number; title: string; description: string; content: DayContent } | null> {
  const { rows } = await pool.query<{
    id: number;
    title: string;
    description: string;
    content: DayContent;
  }>(
    'SELECT id, title, description, content FROM advent_days WHERE id = $1 AND is_published = TRUE',
    [dayId]
  );
  return rows[0] ?? null;
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/services/notifications.ts
import type { Pool } from 'pg';
import type { Api } from 'grammy';

export interface NotificationSender {
  sendMessage: (telegramId: string, text: string) => Promise<void>;
}

export function createGrammySender(api: Api): NotificationSender {
  return {
    sendMessage: async (telegramId: string, text: string) => {
      await api.sendMessage(telegramId, text);
    },
  };
}

export function buildFreePeriodEndedMessage(adminUsername: string): string {
  const cleanHandle = adminUsername.replace(/^@/, '');
  return (
    `🎄 Ваши 7 бесплатных дней адвента подошли к концу!\n\n` +
    `Надеемся, вам понравилось наше маленькое путешествие.\n\n` +
    `Но впереди ещё 18 дней, наполненных новыми заданиями, материалами и открытиями!\n\n` +
    `Чтобы продолжить участие, свяжитесь с организатором: @${cleanHandle}\n\n` +
    `После подтверждения оплаты вам откроется полный доступ к оставшейся части адвента.\n\n` +
    `До встречи!`
  );
}

export function buildPaymentConfirmedMessage(): string {
  return (
    `🎉 Оплата подтверждена!\n\n` +
    `Вам открыт полный доступ ко всем оставшимся дням адвента.\n\n` +
    `Возвращайтесь в Mini App и продолжайте своё путешествие!\n\n` +
    `До встречи!`
  );
}

export async function sendIdempotentNotification(params: {
  pool: Pool;
  sender: NotificationSender;
  userId: number;
  telegramId: string;
  type: 'free_period_ended' | 'payment_confirmed';
  text: string;
}): Promise<{ delivered: boolean; alreadyProcessed: boolean; error?: string }> {
  const { pool, sender, userId, telegramId, type, text } = params;

  const claim = await pool.query<{ id: number }>(
    `
    INSERT INTO notification_log (user_id, notification_type, status)
    VALUES ($1, $2, 'pending')
    ON CONFLICT (user_id, notification_type) DO NOTHING
    RETURNING id
    `,
    [userId, type]
  );

  if (claim.rowCount === 0) {
    return { delivered: false, alreadyProcessed: true };
  }

  try {
    await sender.sendMessage(telegramId, text);
    await pool.query(
      `
      UPDATE notification_log
      SET status = 'sent', sent_at = NOW(), error_message = NULL
      WHERE user_id = $1 AND notification_type = $2
      `,
      [userId, type]
    );
    return { delivered: true, alreadyProcessed: false };
  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    await pool.query(
      `
      UPDATE notification_log
      SET status = 'failed', sent_at = NOW(), error_message = $3
      WHERE user_id = $1 AND notification_type = $2
      `,
      [userId, type, errorMessage]
    );
    return { delivered: false, alreadyProcessed: false, error: errorMessage };
  }
}

export async function dispatchExpiredTrialNotifications(params: {
  pool: Pool;
  sender: NotificationSender;
  adminUsername: string;
}): Promise<{ checked: number; sent: number; failed: number }> {
  const { pool, sender, adminUsername } = params;

  const { rows } = await pool.query<{ id: number; telegram_id: string }>(
    `
    SELECT u.id, u.telegram_id::text AS telegram_id
    FROM users u
    WHERE u.payment_status = 'unpaid'
      AND u.free_period_end <= NOW()
      AND NOT EXISTS (
        SELECT 1
        FROM notification_log nl
        WHERE nl.user_id = u.id
          AND nl.notification_type = 'free_period_ended'
      )
    ORDER BY u.free_period_end ASC
    LIMIT 100
    `
  );

  let sent = 0;
  let failed = 0;
  const text = buildFreePeriodEndedMessage(adminUsername);

  for (const user of rows) {
    await pool.query(
      `
      UPDATE users
      SET access_status = 'expired', updated_at = NOW()
      WHERE id = $1 AND payment_status = 'unpaid' AND access_status <> 'expired'
      `,
      [user.id]
    );

    const result = await sendIdempotentNotification({
      pool,
      sender,
      userId: user.id,
      telegramId: user.telegram_id,
      type: 'free_period_ended',
      text,
    });

    if (result.delivered) sent++;
    else if (!result.alreadyProcessed) failed++;
  }

  return { checked: rows.length, sent, failed };
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/services/payment.ts
import type { Pool } from 'pg';
import {
  buildPaymentConfirmedMessage,
  sendIdempotentNotification,
  type NotificationSender,
} from './notifications';

export interface ConfirmPaymentResult {
  status: 'confirmed' | 'already_paid' | 'user_not_found';
  notificationDelivered: boolean;
  notificationError?: string;
}

export async function confirmUserPayment(params: {
  pool: Pool;
  sender: NotificationSender;
  adminTelegramId: string;
  targetTelegramId: string;
}): Promise<ConfirmPaymentResult> {
  const { pool, sender, adminTelegramId, targetTelegramId } = params;
  const client = await pool.connect();

  let userId: number | null = null;
  let alreadyPaid = false;

  try {
    await client.query('BEGIN');

    const { rows } = await client.query<{ id: number; payment_status: string }>(
      `
      SELECT id, payment_status
      FROM users
      WHERE telegram_id = $1
      FOR UPDATE
      `,
      [targetTelegramId]
    );

    if (rows.length === 0) {
      await client.query('COMMIT');
      return { status: 'user_not_found', notificationDelivered: false };
    }

    userId = rows[0].id;
    if (rows[0].payment_status === 'paid') {
      alreadyPaid = true;
      await client.query('COMMIT');
      return { status: 'already_paid', notificationDelivered: false };
    }

    await client.query(
      `
      UPDATE users
      SET
        payment_status = 'paid',
        access_status = 'full',
        payment_confirmed_at = NOW(),
        payment_confirmed_by = $2,
        updated_at = NOW()
      WHERE id = $1
      `,
      [userId, adminTelegramId]
    );

    await client.query(
      `
      INSERT INTO admin_audit_log (admin_telegram_id, target_user_telegram_id, action, details)
      VALUES ($1, $2, 'confirm_payment', 'Ручное подтверждение оплаты администратором')
      `,
      [adminTelegramId, targetTelegramId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  if (alreadyPaid || userId === null) {
    return { status: 'already_paid', notificationDelivered: false };
  }

  const notif = await sendIdempotentNotification({
    pool,
    sender,
    userId,
    telegramId: targetTelegramId,
    type: 'payment_confirmed',
    text: buildPaymentConfirmedMessage(),
  });

  return {
    status: 'confirmed',
    notificationDelivered: notif.delivered,
    notificationError: notif.error,
  };
}

export async function logUnauthorizedPaidAttempt(
  pool: Pool,
  actorTelegramId: string,
  targetRaw: string
): Promise<void> {
  const targetNumeric = /^\d+$/.test(targetRaw) ? targetRaw : '0';
  await pool.query(
    `
    INSERT INTO admin_audit_log (admin_telegram_id, target_user_telegram_id, action, details)
    VALUES ($1, $2, 'unauthorized_paid_attempt', $3)
    `,
    [actorTelegramId, targetNumeric, `Попытка неавторизованного вызова /paid ${targetRaw}`]
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/middleware/auth.ts
import type { NextFunction, Request, Response } from 'express';
import { getEnv } from '../config/env';
import { verifySessionToken } from '../services/telegramAuth';

export interface AuthenticatedRequest extends Request {
  auth?: {
    userId: number;
    telegramId: string;
  };
}

export function requireAuth(req: AuthenticatedRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      error: 'AUTH_REQUIRED',
      message: 'Требуется вход через Telegram Mini App.',
    });
    return;
  }

  const token = authHeader.slice('Bearer '.length).trim();
  const payload = verifySessionToken(token, getEnv().SESSION_SECRET);
  if (!payload) {
    res.status(401).json({
      error: 'SESSION_EXPIRED',
      message: 'Сессия устарела. Закройте и снова откройте Mini App в Telegram.',
    });
    return;
  }

  req.auth = {
    userId: payload.userId,
    telegramId: payload.telegramId,
  };
  next();
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/routes/api.ts
import { Router } from 'express';
import { z } from 'zod';
import { getEnv } from '../config/env';
import { getPool } from '../db/pool';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth';
import {
  buildCalendarData,
  evaluateDayAccess,
  getPublishedDayById,
  getUserById,
  upsertUserOnLaunch,
} from '../services/access';
import {
  dispatchExpiredTrialNotifications,
  type NotificationSender,
} from '../services/notifications';
import { signSessionToken, verifyTelegramInitData } from '../services/telegramAuth';

const authBodySchema = z.object({
  initData: z.string().min(1),
});

export function createApiRouter(sender: NotificationSender): Router {
  const router = Router();
  const env = getEnv();
  const pool = getPool();

  router.get('/health', async (_req, res) => {
    try {
      await pool.query('SELECT 1');
      res.json({ ok: true });
    } catch {
      res.status(503).json({ ok: false, message: 'База данных временно недоступна' });
    }
  });

  router.get('/config', (_req, res) => {
    res.json({
      botUsername: env.BOT_USERNAME || null,
      adminUsername: env.ADMIN_USERNAME,
    });
  });

  router.post('/auth/telegram', async (req, res) => {
    const parsed = authBodySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({
        error: 'INVALID_REQUEST',
        message: 'Откройте приложение через Telegram-бота.',
      });
      return;
    }

    const verifiedUser = verifyTelegramInitData(parsed.data.initData, env.TELEGRAM_BOT_TOKEN);
    if (!verifiedUser) {
      res.status(401).json({
        error: 'INVALID_INIT_DATA',
        message: 'Не удалось проверить подпись Telegram. Попробуйте открыть Mini App заново.',
      });
      return;
    }

    try {
      const user = await upsertUserOnLaunch(pool, verifiedUser);
      const token = signSessionToken(
        { userId: user.id, telegramId: user.telegram_id },
        env.SESSION_SECRET
      );
      const calendar = await buildCalendarData({
        pool,
        user,
        adminUsername: env.ADMIN_USERNAME,
        strictPaidDrip: env.STRICT_PAID_DRIP,
      });

      res.json({ token, ...calendar });
    } catch (err) {
      console.error('Ошибка в /api/auth/telegram:', err);
      res.status(500).json({
        error: 'SERVER_ERROR',
        message: 'Сервер временно недоступен. Попробуйте чуть позже.',
      });
    }
  });

  router.get('/calendar', requireAuth, async (req: AuthenticatedRequest, res) => {
    try {
      const user = await getUserById(pool, req.auth!.userId);
      if (!user) {
        res.status(401).json({
          error: 'USER_NOT_FOUND',
          message: 'Пользователь не найден. Откройте Mini App заново.',
        });
        return;
      }

      const calendar = await buildCalendarData({
        pool,
        user,
        adminUsername: env.ADMIN_USERNAME,
        strictPaidDrip: env.STRICT_PAID_DRIP,
      });
      res.json(calendar);
    } catch (err) {
      console.error('Ошибка в /api/calendar:', err);
      res.status(500).json({
        error: 'SERVER_ERROR',
        message: 'Не удалось загрузить календарь. Попробуйте обновить страницу.',
      });
    }
  });

  router.get('/days/:dayId', requireAuth, async (req: AuthenticatedRequest, res) => {
    const dayId = Number(req.params.dayId);
    if (!Number.isInteger(dayId) || dayId < 1 || dayId > 25) {
      res.status(400).json({
        error: 'INVALID_DAY',
        message: 'Такого дня адвента не существует.',
      });
      return;
    }

    try {
      const user = await getUserById(pool, req.auth!.userId);
      if (!user) {
        res.status(401).json({ error: 'USER_NOT_FOUND', message: 'Пользователь не найден.' });
        return;
      }

      const now = new Date();
      const access = evaluateDayAccess({
        dayId,
        user,
        now,
        strictPaidDrip: env.STRICT_PAID_DRIP,
      });

      if (!access.accessible) {
        if (access.reason === 'locked_payment') {
          res.status(403).json({
            error: 'PAYMENT_REQUIRED',
            message: `Доступ к дню ${dayId} откроется после подтверждения оплаты организатором @${env.ADMIN_USERNAME}.`,
          });
          return;
        }
        res.status(403).json({
          error: 'DAY_NOT_ARRIVED',
          message: `День ${dayId} ещё не наступил по вашему расписанию.`,
          unlocksAt: access.unlocksAt?.toISOString() ?? null,
        });
        return;
      }

      const [day, progressRes, calendar] = await Promise.all([
        getPublishedDayById(pool, dayId),
        pool.query<{ completed: boolean; completed_at: Date }>(
          'SELECT completed, completed_at FROM user_progress WHERE user_id = $1 AND day_id = $2',
          [user.id, dayId]
        ),
        buildCalendarData({
          pool,
          user,
          adminUsername: env.ADMIN_USERNAME,
          strictPaidDrip: env.STRICT_PAID_DRIP,
          now,
        }),
      ]);

      if (!day) {
        res.status(404).json({ error: 'DAY_NOT_FOUND', message: 'Материалы дня не найдены.' });
        return;
      }

      const progress = progressRes.rows[0];
      res.json({
        day: {
          ...day,
          completed: Boolean(progress?.completed),
          completedAt: progress?.completed_at ? progress.completed_at.toISOString() : null,
        },
        user: calendar.user,
      });
    } catch (err) {
      console.error('Ошибка в /api/days/:dayId:', err);
      res.status(500).json({
        error: 'SERVER_ERROR',
        message: 'Не удалось загрузить материалы дня.',
      });
    }
  });

  router.post('/days/:dayId/complete', requireAuth, async (req: AuthenticatedRequest, res) => {
    const dayId = Number(req.params.dayId);
    if (!Number.isInteger(dayId) || dayId < 1 || dayId > 25) {
      res.status(400).json({ error: 'INVALID_DAY', message: 'Некорректный номер дня.' });
      return;
    }

    try {
      const user = await getUserById(pool, req.auth!.userId);
      if (!user) {
        res.status(401).json({ error: 'USER_NOT_FOUND', message: 'Пользователь не найден.' });
        return;
      }

      const access = evaluateDayAccess({
        dayId,
        user,
        now: new Date(),
        strictPaidDrip: env.STRICT_PAID_DRIP,
      });

      if (!access.accessible) {
        res.status(403).json({
          error: access.reason === 'locked_payment' ? 'PAYMENT_REQUIRED' : 'DAY_NOT_ARRIVED',
          message: 'Нельзя отметить день, к которому пока нет доступа.',
        });
        return;
      }

      const { rows } = await pool.query<{ completed: boolean; completed_at: Date }>(
        `
        INSERT INTO user_progress (user_id, day_id, completed, completed_at)
        VALUES ($1, $2, TRUE, NOW())
        ON CONFLICT (user_id, day_id) DO UPDATE SET
          completed = TRUE,
          completed_at = COALESCE(user_progress.completed_at, NOW())
        RETURNING completed, completed_at
        `,
        [user.id, dayId]
      );

      res.json({
        completed: rows[0].completed,
        completedAt: rows[0].completed_at.toISOString(),
      });
    } catch (err) {
      console.error('Ошибка в /api/days/:dayId/complete:', err);
      res.status(500).json({
        error: 'SERVER_ERROR',
        message: 'Не удалось сохранить прогресс.',
      });
    }
  });

  router.post('/internal/run-notifications', async (req, res) => {
    const secret = req.headers['x-cron-secret'];
    if (secret !== env.CRON_SECRET) {
      res.status(403).json({ error: 'FORBIDDEN' });
      return;
    }

    try {
      const result = await dispatchExpiredTrialNotifications({
        pool,
        sender,
        adminUsername: env.ADMIN_USERNAME,
      });
      res.json({ ok: true, ...result });
    } catch (err) {
      console.error('Ошибка планировщика уведомлений:', err);
      res.status(500).json({ ok: false });
    }
  });

  return router;
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/bot/index.ts
import { Bot, InlineKeyboard } from 'grammy';
import { getEnv } from '../config/env';
import { getPool } from '../db/pool';
import { createGrammySender } from '../services/notifications';
import { confirmUserPayment, logUnauthorizedPaidAttempt } from '../services/payment';

export function createTelegramBot(): Bot {
  const env = getEnv();
  const pool = getPool();
  const bot = new Bot(env.TELEGRAM_BOT_TOKEN);
  const sender = createGrammySender(bot.api);

  const isAdmin = (userId?: number) =>
    userId !== undefined && String(userId) === env.ADMIN_TELEGRAM_ID;

  bot.command('start', async (ctx) => {
    const keyboard = new InlineKeyboard().webApp('🎄 Открыть Адвент-календарь', env.MINI_APP_URL);
    await ctx.reply(
      `Добро пожаловать в «Адвент-календарь»! ✨\n\n` +
        `Вас ждёт 25-дневное путешествие с ежедневными заданиями, материалами и практиками.\n\n` +
        `• Первые 7 дней доступны бесплатно.\n` +
        `• Нажмите на кнопку ниже, чтобы начать день 1.`,
      { reply_markup: keyboard }
    );
  });

  bot.command('help', async (ctx) => {
    const baseText =
      `Доступные команды:\n` +
      `/start — открыть приветствие и кнопку входа в Mini App\n` +
      `/help — показать эту справку\n\n` +
      `По вопросам участия и оплаты обращайтесь к организатору: @${env.ADMIN_USERNAME}`;

    if (isAdmin(ctx.from?.id)) {
      await ctx.reply(
        `${baseText}\n\n` +
          `🔐 Команды администратора:\n` +
          `/paid TELEGRAM_USER_ID — подтвердить оплату и открыть доступ к дням 8–25.\n` +
          `Пример: /paid 123456789`
      );
      return;
    }

    await ctx.reply(baseText);
  });

  bot.command('paid', async (ctx) => {
    const callerId = ctx.from?.id;
    const rawArg = (ctx.match || '').trim();

    if (!isAdmin(callerId)) {
      if (callerId) {
        await logUnauthorizedPaidAttempt(pool, String(callerId), rawArg).catch(() => {});
      }
      await ctx.reply('У вас нет прав для выполнения этой команды.');
      return;
    }

    if (!/^\d+$/.test(rawArg)) {
      await ctx.reply(`Укажите числовой Telegram ID пользователя.\nПример: /paid 123456789`);
      return;
    }

    try {
      const result = await confirmUserPayment({
        pool,
        sender,
        adminTelegramId: String(callerId),
        targetTelegramId: rawArg,
      });

      if (result.status === 'user_not_found') {
        await ctx.reply(
          `❌ Пользователь с Telegram ID ${rawArg} не найден в базе.\n` +
            `Попросите пользователя сначала открыть Mini App хотя бы один раз.`
        );
        return;
      }

      if (result.status === 'already_paid') {
        await ctx.reply(
          `ℹ️ У пользователя ${rawArg} оплата уже была подтверждена ранее. Повторное уведомление не отправлялось.`
        );
        return;
      }

      if (result.notificationDelivered) {
        await ctx.reply(
          `✅ Оплата для пользователя ${rawArg} подтверждена. Полный доступ открыт, уведомление отправлено.`
        );
      } else {
        await ctx.reply(
          `✅ Оплата для пользователя ${rawArg} подтверждена и сохранена в базе, доступ открыт при входе в Mini App.\n` +
            `⚠️ Не удалось доставить сообщение в Telegram (${result.notificationError || 'возможно, пользователь не запускал бота или заблокировал его'}).`
        );
      }
    } catch (err) {
      console.error('Ошибка в команде /paid:', err);
      await ctx.reply('❌ Произошла внутренняя ошибка при подтверждении оплаты.');
    }
  });

  bot.catch((err) => {
    console.error('Ошибка Telegram бота:', err.error);
  });

  return bot;
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/index.ts
import express from 'express';
import path from 'path';
import { webhookCallback } from 'grammy';
import { getEnv } from './config/env';
import { getPool } from './db/pool';
import { runMigrations } from './db/migrate';
import { seedAdventDays } from './db/seed';
import { createApiRouter } from './routes/api';
import { createTelegramBot } from './bot/index';
import {
  createGrammySender,
  dispatchExpiredTrialNotifications,
} from './services/notifications';

async function start() {
  const env = getEnv();
  const pool = getPool();

  await runMigrations(pool);
  await seedAdventDays(pool);

  const bot = createTelegramBot();
  const sender = createGrammySender(bot.api);

  const app = express();
  app.use(express.json());

  if (env.BOT_MODE === 'webhook') {
    app.post(
      '/api/telegram/webhook',
      (req, res, next) => {
        if (req.headers['x-telegram-bot-api-secret-token'] !== env.TELEGRAM_WEBHOOK_SECRET) {
          res.status(403).send('Forbidden');
          return;
        }
        next();
      },
      webhookCallback(bot, 'express')
    );
  }

  app.use('/api', createApiRouter(sender));

  if (env.NODE_ENV === 'production') {
    const staticDir = path.resolve(process.cwd(), 'dist/client');
    app.use(express.static(staticDir));
    app.get('*', (req, res, next) => {
      if (req.path.startsWith('/api')) {
        next();
        return;
      }
      res.sendFile(path.join(staticDir, 'index.html'));
    });
  } else {
    const { createServer: createViteServer } = await import('vite');
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  }

  app.listen(env.PORT, '0.0.0.0', async () => {
    console.log(`🚀 Сервер запущен на порту ${env.PORT} (${env.NODE_ENV}, бот: ${env.BOT_MODE})`);

    if (env.MINI_APP_URL.startsWith('https://')) {
      try {
        await bot.api.setChatMenuButton({
          menu_button: {
            type: 'web_app',
            text: 'Адвент',
            web_app: { url: env.MINI_APP_URL },
          },
        });
      } catch (err) {
        console.warn('Не удалось установить Menu Button:', err);
      }
    }

    if (env.BOT_MODE === 'webhook') {
      const webhookUrl = `${env.MINI_APP_URL.replace(/\/$/, '')}/api/telegram/webhook`;
      try {
        await bot.api.setWebhook(webhookUrl, {
          secret_token: env.TELEGRAM_WEBHOOK_SECRET,
        });
        console.log(`✅ Telegram Webhook установлен: ${webhookUrl}`);
      } catch (err) {
        console.error('❌ Ошибка установки Telegram Webhook:', err);
      }
    } else {
      bot
        .start({
          onStart: (botInfo) => {
            console.log(`🤖 Бот @${botInfo.username} запущен (long polling).`);
          },
        })
        .catch((err) => {
          console.error('❌ Ошибка запуска long polling бота:', err);
        });
    }

    const runSchedulerTick = async () => {
      try {
        const res = await dispatchExpiredTrialNotifications({
          pool,
          sender,
          adminUsername: env.ADMIN_USERNAME,
        });
        if (res.checked > 0) {
          console.log(
            `📬 Проверка окончания триала: найдено ${res.checked}, отправлено ${res.sent}, ошибок ${res.failed}`
          );
        }
      } catch (err) {
        console.error('Ошибка фоновой проверки уведомлений:', err);
      }
    };

    void runSchedulerTick();
    setInterval(runSchedulerTick, 60_000);
  });
}

start().catch((err) => {
  console.error('❌ Критическая ошибка старта:', err);
  process.exit(1);
});
__END_OF_FILE__

cat << '__END_OF_FILE__' > server/tests/app.test.ts
import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'crypto';
import { verifyTelegramInitData, signSessionToken, verifySessionToken } from '../services/telegramAuth';
import { evaluateDayAccess, type UserRow } from '../services/access';

function buildSignedInitData(userObj: object, botToken: string, authDateSec?: number): string {
  const params = new URLSearchParams();
  params.set('auth_date', String(authDateSec ?? Math.floor(Date.now() / 1000)));
  params.set('query_id', 'AAHdF6IQAAAAAN0XohDhrOrc');
  params.set('user', JSON.stringify(userObj));

  const dataCheckString = Array.from(params.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => `${k}=${v}`)
    .join('\n');

  const secretKey = crypto.createHmac('sha256', 'WebAppData').update(botToken).digest();
  const hash = crypto.createHmac('sha256', secretKey).update(dataCheckString).digest('hex');
  params.set('hash', hash);
  return params.toString();
}

test('verifyTelegramInitData принимает валидную подпись и отклоняет подделанную', () => {
  const token = '123456:TEST_BOT_TOKEN_FOR_TESTS';
  const initData = buildSignedInitData({ id: 987654321, username: 'ivan', first_name: 'Иван' }, token);

  const verified = verifyTelegramInitData(initData, token);
  assert.ok(verified);
  assert.equal(verified.telegramId, '987654321');
  assert.equal(verified.firstName, 'Иван');

  const tampered = initData.replace('987654321', '111111111');
  assert.equal(verifyTelegramInitData(tampered, token), null);
});

test('Сессионный токен защищён от подделки', () => {
  const token = signSessionToken({ userId: 42, telegramId: '555' }, 'secret-key');
  const ok = verifySessionToken(token, 'secret-key');
  assert.equal(ok?.userId, 42);
  assert.equal(verifySessionToken(token + 'x', 'secret-key'), null);
});

test('Контроль доступа: дни 1–7 по таймлайну, 8–25 строго после оплаты', () => {
  const regDate = new Date('2026-12-01T10:00:00Z');
  const unpaidUser: UserRow = {
    id: 1,
    telegram_id: '100',
    telegram_username: 'test',
    first_name: 'Тест',
    registration_date: regDate,
    free_period_end: new Date(regDate.getTime() + 168 * 3600 * 1000),
    payment_status: 'unpaid',
    access_status: 'free',
    payment_confirmed_at: null,
    payment_confirmed_by: null,
  };

  const twoHoursLater = new Date(regDate.getTime() + 2 * 3600 * 1000);
  assert.equal(
    evaluateDayAccess({ dayId: 1, user: unpaidUser, now: twoHoursLater, strictPaidDrip: false }).accessible,
    true
  );
  assert.equal(
    evaluateDayAccess({ dayId: 2, user: unpaidUser, now: twoHoursLater, strictPaidDrip: false }).reason,
    'locked_time'
  );
  assert.equal(
    evaluateDayAccess({ dayId: 8, user: unpaidUser, now: twoHoursLater, strictPaidDrip: false }).reason,
    'locked_payment'
  );

  const tenDaysLater = new Date(regDate.getTime() + 10 * 24 * 3600 * 1000);
  assert.equal(
    evaluateDayAccess({ dayId: 7, user: unpaidUser, now: tenDaysLater, strictPaidDrip: false }).accessible,
    true
  );
  assert.equal(
    evaluateDayAccess({ dayId: 8, user: unpaidUser, now: tenDaysLater, strictPaidDrip: false }).reason,
    'locked_payment'
  );

  const paidUser: UserRow = { ...unpaidUser, payment_status: 'paid', access_status: 'full' };
  assert.equal(
    evaluateDayAccess({ dayId: 25, user: paidUser, now: tenDaysLater, strictPaidDrip: false }).accessible,
    true
  );
});
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/index.html
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Адвент-календарь</title>
    <script src="https://telegram.org/js/telegram-web-app.js"></script>
  </head>
  <body class="bg-pine-950 text-ivory-50 antialiased">
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Inter, sans-serif;
    background-color: #081813;
    color: #fcf9f2;
    min-height: 100vh;
  }
}

.card-appear {
  animation: fadeSlideUp 0.35s ease-out both;
}

@keyframes fadeSlideUp {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/api/client.ts
import type { CalendarResponse, DayDetailResponse } from '@shared/types';

let authToken: string | null = null;

export class ApiError extends Error {
  status: number;
  code: string;
  unlocksAt?: string | null;

  constructor(status: number, code: string, message: string, unlocksAt?: string | null) {
    super(message);
    this.status = status;
    this.code = code;
    this.unlocksAt = unlocksAt;
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((options.headers as Record<string, string>) || {}),
  };
  if (authToken) {
    headers.Authorization = `Bearer ${authToken}`;
  }

  let response: Response;
  try {
    response = await fetch(`/api${path}`, { ...options, headers });
  } catch {
    throw new ApiError(0, 'NETWORK_ERROR', 'Сервер временно недоступен. Проверьте интернет.');
  }

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new ApiError(
      response.status,
      data.error || 'UNKNOWN_ERROR',
      data.message || 'Произошла ошибка. Попробуйте ещё раз.',
      data.unlocksAt
    );
  }

  return data as T;
}

export async function authenticateWithTelegram(initData: string): Promise<CalendarResponse> {
  const result = await request<CalendarResponse & { token: string }>('/auth/telegram', {
    method: 'POST',
    body: JSON.stringify({ initData }),
  });
  authToken = result.token;
  return { user: result.user, days: result.days };
}

export function fetchCalendar(): Promise<CalendarResponse> {
  return request<CalendarResponse>('/calendar');
}

export function fetchDayDetail(dayId: number): Promise<DayDetailResponse> {
  return request<DayDetailResponse>(`/days/${dayId}`);
}

export function markDayComplete(dayId: number): Promise<{ completed: boolean; completedAt: string }> {
  return request<{ completed: boolean; completedAt: string }>(`/days/${dayId}/complete`, {
    method: 'POST',
  });
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/components/OutsideTelegram.tsx
import { useEffect, useState } from 'react';
import { Sparkles, ExternalLink } from 'lucide-react';

export function OutsideTelegram() {
  const [botUsername, setBotUsername] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/config')
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (data?.botUsername) setBotUsername(data.botUsername);
      })
      .catch(() => {});
  }, []);

  const targetUrl = botUsername ? `https://t.me/${botUsername}` : 'https://t.me';

  return (
    <div className="min-h-screen bg-gradient-to-b from-pine-950 via-pine-900 to-pine-950 flex items-center justify-center p-6">
      <div className="max-w-md w-full bg-pine-800/70 border border-gold-500/30 rounded-3xl p-7 text-center shadow-2xl">
        <div className="w-14 h-14 mx-auto mb-4 rounded-2xl bg-gold-500/15 border border-gold-500/40 flex items-center justify-center">
          <Sparkles className="w-7 h-7 text-gold-400" />
        </div>
        <h1 className="text-2xl font-semibold text-ivory-50 mb-3">Адвент-календарь</h1>
        <p className="text-ivory-200/90 text-sm leading-relaxed mb-6">
          Это приложение работает только внутри Telegram как Mini App. Пожалуйста, откройте его через
          официального Telegram-бота, чтобы ваш прогресс и доступ сохранились автоматически.
        </p>
        <a
          href={targetUrl}
          target="_blank"
          rel="noreferrer"
          className="inline-flex items-center justify-center gap-2 w-full py-3.5 px-5 rounded-2xl bg-gold-500 hover:bg-gold-400 text-pine-950 font-semibold transition"
        >
          <span>{botUsername ? `Открыть @${botUsername}` : 'Открыть Telegram'}</span>
          <ExternalLink className="w-4 h-4" />
        </a>
      </div>
    </div>
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/components/ProgressHeader.tsx
import { useEffect, useState } from 'react';
import { Crown, Clock, RefreshCw, Sparkles, MessageCircle } from 'lucide-react';
import type { UserAccessSummary } from '@shared/types';

interface Props {
  user: UserAccessSummary;
  onRefresh: () => void;
  refreshing: boolean;
  onContactAdmin: () => void;
}

function formatCountdown(targetIso: string | null, nowMs: number): string | null {
  if (!targetIso) return null;
  const diff = new Date(targetIso).getTime() - nowMs;
  if (diff <= 0) return null;

  const hours = Math.floor(diff / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const days = Math.floor(hours / 24);
  const remHours = hours % 24;

  if (days > 0) return `${days} дн. ${remHours} ч.`;
  return `${hours} ч. ${minutes} мин.`;
}

export function ProgressHeader({ user, onRefresh, refreshing, onContactAdmin }: Props) {
  const [nowMs, setNowMs] = useState(Date.now());

  useEffect(() => {
    const id = setInterval(() => setNowMs(Date.now()), 30_000);
    return () => clearInterval(id);
  }, []);

  const progressPercent = Math.round((user.completedCount / user.totalDays) * 100);
  const freeTimeLeft = formatCountdown(user.freePeriodEnd, nowMs);
  const nextDayLeft = formatCountdown(user.nextDayUnlocksAt, nowMs);

  return (
    <header className="space-y-4">
      <div className="bg-gradient-to-br from-pine-800/90 to-pine-900/95 border border-gold-500/25 rounded-3xl p-5 shadow-xl">
        <div className="flex items-start justify-between gap-3">
          <div>
            <div className="inline-flex items-center gap-1.5 text-xs font-medium text-gold-400 bg-gold-500/10 border border-gold-500/25 px-2.5 py-1 rounded-full mb-2.5">
              <Sparkles className="w-3.5 h-3.5" />
              <span>25 дней вдохновения</span>
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-ivory-50">Адвент-календарь</h1>
            <p className="text-sm text-ivory-200/80 mt-1">
              Здравствуйте, {user.firstName}! Открывайте по одному дню и выполняйте задания.
            </p>
          </div>
          <button
            onClick={onRefresh}
            disabled={refreshing}
            aria-label="Обновить статус"
            className="p-2.5 rounded-2xl bg-pine-950/60 border border-ivory-200/15 text-ivory-200 hover:text-gold-400 transition disabled:opacity-50"
          >
            <RefreshCw className={`w-4 h-4 ${refreshing ? 'animate-spin' : ''}`} />
          </button>
        </div>

        <div className="mt-5">
          <div className="flex items-center justify-between text-xs text-ivory-200/90 mb-2">
            <span className="font-medium">
              День {user.currentTimelineDay} из {user.totalDays}
            </span>
            <span>
              Пройдено: {user.completedCount} из {user.totalDays} ({progressPercent}%)
            </span>
          </div>
          <div className="h-2.5 w-full rounded-full bg-pine-950/80 overflow-hidden border border-ivory-200/10">
            <div
              className="h-full rounded-full bg-gradient-to-r from-gold-600 via-gold-400 to-ivory-100 transition-all duration-500"
              style={{ width: `${Math.max(4, progressPercent)}%` }}
            />
          </div>
        </div>

        <div className="mt-4 pt-4 border-t border-ivory-200/10 flex flex-wrap items-center justify-between gap-2 text-xs">
          {user.accessStatus === 'full' && (
            <div className="inline-flex items-center gap-1.5 text-emerald-300 font-medium">
              <Crown className="w-4 h-4 text-gold-400" />
              <span>Полный доступ ко всем 25 дням открыт</span>
            </div>
          )}

          {user.accessStatus === 'free' && (
            <div className="inline-flex items-center gap-1.5 text-ivory-100">
              <Clock className="w-4 h-4 text-gold-400" />
              <span>
                Бесплатный период (дни 1–7){freeTimeLeft ? `: осталось ${freeTimeLeft}` : ''}
              </span>
            </div>
          )}

          {user.accessStatus === 'expired' && (
            <div className="w-full bg-berry-700/35 border border-berry-600/60 rounded-2xl p-3.5 space-y-2.5">
              <p className="text-ivory-50 text-xs leading-relaxed">
                Ваши 7 бесплатных дней завершились. Чтобы открыть доступ к дням 8–25, свяжитесь с
                организатором @{user.adminUsername}.
              </p>
              <div className="flex flex-wrap gap-2">
                <button
                  onClick={onContactAdmin}
                  className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-gold-500 hover:bg-gold-400 text-pine-950 font-semibold text-xs transition"
                >
                  <MessageCircle className="w-3.5 h-3.5" />
                  <span>Написать @{user.adminUsername}</span>
                </button>
                <button
                  onClick={onRefresh}
                  disabled={refreshing}
                  className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-pine-950/60 border border-ivory-200/20 text-ivory-100 text-xs transition"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
                  <span>Я оплатил(а) — проверить</span>
                </button>
              </div>
            </div>
          )}

          {nextDayLeft && user.nextDayId && (
            <div className="text-ivory-200/75">
              День {user.nextDayId} откроется через {nextDayLeft}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/components/DayCard.tsx
import { CheckCircle2, Clock, Lock, Sparkles } from 'lucide-react';
import type { CalendarDaySummary } from '@shared/types';

interface Props {
  day: CalendarDaySummary;
  onClick: (day: CalendarDaySummary) => void;
}

export function DayCard({ day, onClick }: Props) {
  const cardStyles: Record<CalendarDaySummary['state'], string> = {
    available:
      'bg-gradient-to-br from-pine-700/90 to-pine-800/95 border-gold-400/70 hover:border-gold-400 shadow-lg shadow-gold-500/10',
    completed:
      'bg-gradient-to-br from-pine-800/90 to-pine-900/95 border-emerald-400/50',
    locked_time:
      'bg-pine-900/60 border-ivory-200/10 opacity-75',
    locked_payment:
      'bg-pine-900/45 border-berry-600/35 opacity-80',
  };

  const stateBadge: Record<CalendarDaySummary['state'], { text: string; color: string }> = {
    available: { text: 'Открыт', color: 'text-gold-400' },
    completed: { text: 'Пройден', color: 'text-emerald-300' },
    locked_time: { text: 'Скоро', color: 'text-ivory-200/60' },
    locked_payment: { text: 'По оплате', color: 'text-rose-300' },
  };

  return (
    <button
      type="button"
      onClick={() => onClick(day)}
      style={{ animationDelay: `${Math.min(day.id * 18, 350)}ms` }}
      className={`card-appear relative flex flex-col justify-between text-left rounded-2xl border p-3.5 min-h-[104px] transition active:scale-[0.98] cursor-pointer ${cardStyles[day.state]}`}
    >
      <div className="flex items-center justify-between w-full">
        <span className="text-xl font-bold text-ivory-50">{day.id}</span>
        {day.state === 'completed' && <CheckCircle2 className="w-4 h-4 text-emerald-300" />}
        {day.state === 'available' && <Sparkles className="w-4 h-4 text-gold-400" />}
        {day.state === 'locked_time' && <Clock className="w-4 h-4 text-ivory-200/50" />}
        {day.state === 'locked_payment' && <Lock className="w-4 h-4 text-rose-300/80" />}
      </div>

      <div className="mt-2">
        <div className={`text-[11px] font-medium ${stateBadge[day.state].color}`}>
          {stateBadge[day.state].text}
        </div>
        <div className="text-[11px] text-ivory-200/75 line-clamp-1 mt-0.5">
          {day.id <= 7 ? 'Бесплатный' : 'Полный доступ'}
        </div>
      </div>
    </button>
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/components/RichContentBlocks.tsx
import { Download, ExternalLink, Headphones, PlayCircle, CheckSquare } from 'lucide-react';
import type { DayContent } from '@shared/types';

function toEmbedUrl(url: string): string | null {
  try {
    const u = new URL(url);
    if (u.hostname.includes('youtube.com') && u.searchParams.get('v')) {
      return `https://www.youtube.com/embed/${u.searchParams.get('v')}`;
    }
    if (u.hostname === 'youtu.be') {
      return `https://www.youtube.com/embed${u.pathname}`;
    }
  } catch {
    return null;
  }
  return null;
}

export function RichContentBlocks({ content }: { content: DayContent }) {
  return (
    <div className="space-y-5">
      <section className="bg-pine-800/60 border border-ivory-200/10 rounded-3xl p-5">
        <div className="text-ivory-50/95 text-[15px] leading-relaxed whitespace-pre-line">
          {content.mainText}
        </div>
      </section>

      {content.images && content.images.length > 0 && (
        <section className="space-y-3">
          {content.images.map((img, i) => (
            <figure
              key={i}
              className="overflow-hidden rounded-3xl border border-ivory-200/15 bg-pine-900/60"
            >
              <img src={img.url} alt={img.caption || 'Иллюстрация'} className="w-full object-cover" />
              {img.caption && (
                <figcaption className="px-4 py-2.5 text-xs text-ivory-200/80">
                  {img.caption}
                </figcaption>
              )}
            </figure>
          ))}
        </section>
      )}

      {content.videos && content.videos.length > 0 && (
        <section className="space-y-3">
          {content.videos.map((video, i) => {
            const embed = video.embedUrl || toEmbedUrl(video.url);
            return (
              <div
                key={i}
                className="bg-pine-800/60 border border-ivory-200/15 rounded-3xl p-4 space-y-3"
              >
                <div className="flex items-center gap-2 text-sm font-semibold text-gold-400">
                  <PlayCircle className="w-4 h-4" />
                  <span>{video.title}</span>
                </div>
                {embed ? (
                  <div className="aspect-video w-full overflow-hidden rounded-2xl bg-pine-950">
                    <iframe
                      src={embed}
                      title={video.title}
                      className="w-full h-full"
                      allowFullScreen
                    />
                  </div>
                ) : null}
                <a
                  href={video.url}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1.5 text-xs text-ivory-100 underline decoration-gold-500/60"
                >
                  <span>Открыть видео в новом окне</span>
                  <ExternalLink className="w-3.5 h-3.5" />
                </a>
              </div>
            );
          })}
        </section>
      )}

      {content.audios && content.audios.length > 0 && (
        <section className="space-y-3">
          {content.audios.map((audio, i) => (
            <div
              key={i}
              className="bg-pine-800/60 border border-ivory-200/15 rounded-3xl p-4 space-y-2.5"
            >
              <div className="flex items-center gap-2 text-sm font-semibold text-gold-400">
                <Headphones className="w-4 h-4" />
                <span>{audio.title}</span>
              </div>
              <audio controls preload="none" className="w-full">
                <source src={audio.url} />
                Ваш браузер не поддерживает воспроизведение аудио.
              </audio>
            </div>
          ))}
        </section>
      )}

      {content.task && (
        <section className="bg-gradient-to-br from-gold-500/15 to-pine-800/80 border border-gold-500/40 rounded-3xl p-5 space-y-2">
          <div className="flex items-center gap-2 text-gold-400 font-semibold text-sm">
            <CheckSquare className="w-4 h-4" />
            <span>{content.task.title}</span>
          </div>
          <p className="text-sm text-ivory-50/95 leading-relaxed">{content.task.description}</p>
        </section>
      )}

      {content.links && content.links.length > 0 && (
        <section className="bg-pine-800/60 border border-ivory-200/10 rounded-3xl p-4 space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wider text-ivory-200/70">
            Дополнительные материалы
          </h3>
          <div className="space-y-2">
            {content.links.map((link, i) => (
              <a
                key={i}
                href={link.url}
                target="_blank"
                rel="noreferrer"
                className="flex items-center justify-between px-3.5 py-2.5 rounded-2xl bg-pine-950/60 border border-ivory-200/10 text-sm text-ivory-100 hover:border-gold-400/50 transition"
              >
                <span>{link.label}</span>
                <ExternalLink className="w-4 h-4 text-gold-400 shrink-0" />
              </a>
            ))}
          </div>
        </section>
      )}

      {content.downloads && content.downloads.length > 0 && (
        <section className="bg-pine-800/60 border border-ivory-200/10 rounded-3xl p-4 space-y-2">
          <h3 className="text-xs font-semibold uppercase tracking-wider text-ivory-200/70">
            Материалы для скачивания
          </h3>
          <div className="space-y-2">
            {content.downloads.map((file, i) => (
              <a
                key={i}
                href={file.url}
                target="_blank"
                rel="noreferrer"
                className="flex items-center justify-between px-3.5 py-2.5 rounded-2xl bg-pine-950/60 border border-ivory-200/10 text-sm text-ivory-100 hover:border-gold-400/50 transition"
              >
                <div>
                  <div>{file.label}</div>
                  {file.fileSize && (
                    <div className="text-[11px] text-ivory-200/60">{file.fileSize}</div>
                  )}
                </div>
                <Download className="w-4 h-4 text-gold-400 shrink-0" />
              </a>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/pages/CalendarPage.tsx
import { useState } from 'react';
import { Lock, MessageCircle, X } from 'lucide-react';
import type { CalendarDaySummary, CalendarResponse } from '@shared/types';
import { ProgressHeader } from '../components/ProgressHeader';
import { DayCard } from '../components/DayCard';

interface Props {
  data: CalendarResponse;
  onOpenDay: (dayId: number) => void;
  onRefresh: () => void;
  refreshing: boolean;
  onContactAdmin: () => void;
}

export function CalendarPage({
  data,
  onOpenDay,
  onRefresh,
  refreshing,
  onContactAdmin,
}: Props) {
  const [lockedModalDay, setLockedModalDay] = useState<CalendarDaySummary | null>(null);

  const handleDayClick = (day: CalendarDaySummary) => {
    if (day.state === 'available' || day.state === 'completed') {
      onOpenDay(day.id);
      return;
    }
    setLockedModalDay(day);
  };

  return (
    <div className="max-w-xl mx-auto px-4 pt-4 pb-10 space-y-5">
      <ProgressHeader
        user={data.user}
        onRefresh={onRefresh}
        refreshing={refreshing}
        onContactAdmin={onContactAdmin}
      />

      <main>
        <div className="grid grid-cols-3 sm:grid-cols-5 gap-3">
          {data.days.map((day) => (
            <DayCard key={day.id} day={day} onClick={handleDayClick} />
          ))}
        </div>
      </main>

      {lockedModalDay && (
        <div className="fixed inset-0 z-50 bg-pine-950/80 backdrop-blur-sm flex items-end sm:items-center justify-center p-4">
          <div className="w-full max-w-md bg-pine-900 border border-gold-500/30 rounded-3xl p-6 space-y-4 shadow-2xl">
            <div className="flex items-start justify-between">
              <div className="inline-flex items-center gap-2 text-gold-400 font-semibold">
                <Lock className="w-5 h-5" />
                <span>День {lockedModalDay.id} пока закрыт</span>
              </div>
              <button
                onClick={() => setLockedModalDay(null)}
                className="p-1.5 rounded-xl text-ivory-200/70 hover:text-ivory-50"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {lockedModalDay.state === 'locked_time' ? (
              <p className="text-sm text-ivory-200/90 leading-relaxed">
                Этот день ещё не наступил по вашему личному расписанию.
                {lockedModalDay.unlocksAt
                  ? ` Он откроется ${new Date(lockedModalDay.unlocksAt).toLocaleString('ru-RU', {
                      day: 'numeric',
                      month: 'long',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}.`
                  : ''}
              </p>
            ) : (
              <div className="space-y-3">
                <p className="text-sm text-ivory-200/90 leading-relaxed">
                  Дни 8–25 доступны после подтверждения оплаты. Свяжитесь с организатором @
                  {data.user.adminUsername}, чтобы получить ссылку на оплату и открыть полный доступ.
                </p>
                <div className="flex flex-col sm:flex-row gap-2">
                  <button
                    onClick={() => {
                      setLockedModalDay(null);
                      onContactAdmin();
                    }}
                    className="flex-1 inline-flex items-center justify-center gap-2 py-3 px-4 rounded-2xl bg-gold-500 hover:bg-gold-400 text-pine-950 font-semibold text-sm transition"
                  >
                    <MessageCircle className="w-4 h-4" />
                    <span>Написать организатору</span>
                  </button>
                  <button
                    onClick={() => {
                      setLockedModalDay(null);
                      onRefresh();
                    }}
                    className="py-3 px-4 rounded-2xl bg-pine-800 border border-ivory-200/20 text-ivory-100 text-sm font-medium"
                  >
                    Обновить статус
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/pages/DayPage.tsx
import { useEffect, useState } from 'react';
import { ArrowLeft, CheckCircle2, Loader2 } from 'lucide-react';
import WebApp from '@twa-dev/sdk';
import type { DayDetailResponse } from '@shared/types';
import { fetchDayDetail, markDayComplete, ApiError } from '../api/client';
import { RichContentBlocks } from '../components/RichContentBlocks';

interface Props {
  dayId: number;
  onBack: () => void;
  onCompleted: () => void;
}

export function DayPage({ dayId, onBack, onCompleted }: Props) {
  const [detail, setDetail] = useState<DayDetailResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);

    fetchDayDetail(dayId)
      .then((res) => {
        if (active) setDetail(res);
      })
      .catch((err) => {
        if (active) {
          setError(
            err instanceof ApiError ? err.message : 'Не удалось загрузить материалы этого дня.'
          );
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    try {
      WebApp.BackButton.show();
      WebApp.BackButton.onClick(onBack);
    } catch {
      // ignore outside TG
    }

    return () => {
      active = false;
      try {
        WebApp.BackButton.offClick(onBack);
        WebApp.BackButton.hide();
      } catch {
        // ignore
      }
    };
  }, [dayId, onBack]);

  const handleComplete = async () => {
    if (!detail || detail.day.completed || submitting) return;
    setSubmitting(true);
    try {
      const res = await markDayComplete(dayId);
      setDetail({
        ...detail,
        day: { ...detail.day, completed: res.completed, completedAt: res.completedAt },
      });
      onCompleted();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Не удалось сохранить отметку.');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-3 p-6 text-ivory-200">
        <Loader2 className="w-7 h-7 animate-spin text-gold-400" />
        <p className="text-sm">Загружаем день {dayId}...</p>
      </div>
    );
  }

  if (error || !detail) {
    return (
      <div className="max-w-xl mx-auto p-5 space-y-4">
        <button
          onClick={onBack}
          className="inline-flex items-center gap-2 text-sm text-gold-400 font-medium"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Назад к календарю</span>
        </button>
        <div className="bg-berry-700/35 border border-berry-600/60 rounded-3xl p-5 text-sm text-ivory-50">
          {error || 'Не удалось открыть страницу дня.'}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-xl mx-auto px-4 pt-4 pb-12 space-y-5">
      <button
        onClick={onBack}
        className="inline-flex items-center gap-2 text-sm text-gold-400 hover:text-gold-400/80 font-medium"
      >
        <ArrowLeft className="w-4 h-4" />
        <span>Назад к календарю</span>
      </button>

      <div className="space-y-2">
        <div className="inline-block text-xs font-semibold uppercase tracking-wider text-gold-400 bg-gold-500/10 border border-gold-500/25 px-3 py-1 rounded-full">
          День {detail.day.id} из 25
        </div>
        <h1 className="text-2xl font-bold text-ivory-50">{detail.day.title}</h1>
        <p className="text-sm text-ivory-200/85 leading-relaxed">{detail.day.description}</p>
      </div>

      <RichContentBlocks content={detail.day.content} />

      <div className="pt-2">
        {detail.day.completed ? (
          <div className="w-full py-3.5 px-5 rounded-2xl bg-emerald-500/15 border border-emerald-400/40 text-emerald-200 font-semibold text-sm flex items-center justify-center gap-2">
            <CheckCircle2 className="w-5 h-5" />
            <span>День отмечен как пройденный</span>
          </div>
        ) : (
          <button
            onClick={handleComplete}
            disabled={submitting}
            className="w-full py-4 px-5 rounded-2xl bg-gold-500 hover:bg-gold-400 text-pine-950 font-semibold text-sm transition flex items-center justify-center gap-2 disabled:opacity-60"
          >
            {submitting ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <CheckCircle2 className="w-5 h-5" />
            )}
            <span>Отметить день как пройденный</span>
          </button>
        )}
      </div>
    </div>
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > client/src/App.tsx
import { useCallback, useEffect, useState } from 'react';
import WebApp from '@twa-dev/sdk';
import { Loader2, RefreshCw } from 'lucide-react';
import type { CalendarResponse } from '@shared/types';
import { ApiError, authenticateWithTelegram, fetchCalendar } from './api/client';
import { OutsideTelegram } from './components/OutsideTelegram';
import { CalendarPage } from './pages/CalendarPage';
import { DayPage } from './pages/DayPage';

export default function App() {
  const [outsideTelegram, setOutsideTelegram] = useState(false);
  const [calendar, setCalendar] = useState<CalendarResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedDayId, setSelectedDayId] = useState<number | null>(null);

  const initApp = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      WebApp.ready();
      WebApp.expand();
    } catch {
      // ignore
    }

    const initData = WebApp.initData;
    if (!initData) {
      setOutsideTelegram(true);
      setLoading(false);
      return;
    }

    try {
      const data = await authenticateWithTelegram(initData);
      setCalendar(data);
    } catch (err) {
      setError(
        err instanceof ApiError
          ? err.message
          : 'Сервер временно недоступен. Попробуйте обновить экран.'
      );
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void initApp();
  }, [initApp]);

  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    setError(null);
    try {
      const updated = await fetchCalendar();
      setCalendar(updated);
    } catch (err) {
      if (err instanceof ApiError && err.status === 401 && WebApp.initData) {
        const reAuth = await authenticateWithTelegram(WebApp.initData);
        setCalendar(reAuth);
      } else {
        setError(err instanceof ApiError ? err.message : 'Не удалось обновить статус доступа.');
      }
    } finally {
      setRefreshing(false);
    }
  }, []);

  const handleContactAdmin = useCallback(() => {
    if (!calendar) return;
    const url = `https://t.me/${calendar.user.adminUsername}`;
    try {
      WebApp.openTelegramLink(url);
    } catch {
      window.open(url, '_blank');
    }
  }, [calendar]);

  if (outsideTelegram) {
    return <OutsideTelegram />;
  }

  if (loading) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-3 p-6 text-ivory-200">
        <Loader2 className="w-8 h-8 animate-spin text-gold-400" />
        <p className="text-sm">Загружаем ваш адвент-календарь...</p>
      </div>
    );
  }

  if (error && !calendar) {
    return (
      <div className="min-h-screen flex items-center justify-center p-6">
        <div className="max-w-sm w-full bg-pine-800/70 border border-berry-600/60 rounded-3xl p-6 text-center space-y-4">
          <p className="text-sm text-ivory-50">{error}</p>
          <button
            onClick={initApp}
            className="inline-flex items-center gap-2 px-5 py-3 rounded-2xl bg-gold-500 text-pine-950 font-semibold text-sm"
          >
            <RefreshCw className="w-4 h-4" />
            <span>Повторить</span>
          </button>
        </div>
      </div>
    );
  }

  if (!calendar) return null;

  if (selectedDayId !== null) {
    return (
      <DayPage
        dayId={selectedDayId}
        onBack={() => setSelectedDayId(null)}
        onCompleted={() => void handleRefresh()}
      />
    );
  }

  return (
    <CalendarPage
      data={calendar}
      onOpenDay={(id) => setSelectedDayId(id)}
      onRefresh={() => void handleRefresh()}
      refreshing={refreshing}
      onContactAdmin={handleContactAdmin}
    />
  );
}
__END_OF_FILE__

cat << '__END_OF_FILE__' > README.md
# Адвент-календарь (Telegram Mini App)

## 1. Создание бота в BotFather
1. Откройте `@BotFather` в Telegram и выполните `/newbot`.
2. Сохраните `TELEGRAM_BOT_TOKEN` и `BOT_USERNAME`.
3. Настройте Mini App: выполните `/setmenubutton`, выберите бота, укажите публичный HTTPS-адрес приложения (`MINI_APP_URL`) и текст кнопки `Адвент`.

## 2. Настройка Replit Secrets
В Replit откройте вкладку **Secrets** и добавьте:
- `DATABASE_URL` — создаётся автоматически при подключении встроенной Replit PostgreSQL.
- `TELEGRAM_BOT_TOKEN` — токен от BotFather.
- `ADMIN_TELEGRAM_ID` — числовой Telegram ID администратора (можно узнать в `@userinfobot`).
- `ADMIN_USERNAME` — username организатора без `@`.
- `MINI_APP_URL` — публичный HTTPS URL вашего Replit-приложения.
- `BOT_USERNAME` — username бота без `@`.
- `BOT_MODE` — `polling` (для разработки / Reserved VM) или `webhook` (для Autoscale).

## 3. Первый запуск
```bash
npm install
npm run db:migrate
npm run db:seed
npm run dev