===========================================================================
SCHOLARS READ-ONLY SOURCE AUDIT

GitHub Personal Access Token: ··········

Repository: ImperioKDB/Scholars
Branch: cloudflare/migration-preparation-20261121
Commit: 1c2a92d966447c17bab7a7db38877856bc46f690
PR: #41
PR status: open
Preflight: PASS

Branch archive downloaded successfully.

#####################################################################################
FILE: app/admin/analytics/page.tsx
#####################################################################################
STATUS: FOUND
TOTAL LINES: 98
SHA-256: 210bdfdd64ae91524c7e02c41a7d78f3ab56353c19a77545a66e66b45efa64c0

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 46:
export default async function ProviderAnalyticsPage({ searchParams }: { searchParams?: { range?: string } }) {

Line 48:
const range = parseProviderAnalyticsRange(searchParams?.range);

COMPLETE SOURCE CODE

1 | import Link from "next/link";
2 | import { createClient } from "@/lib/supabase/server";
3 | import { requireAdmin } from "@/lib/admin/access";
4 | import { getAutonomousFixLogs } from "@/lib/admin/fix-log";
5 | import {
6 |   getProviderAnalyticsWindow,
7 |   parseProviderAnalyticsRange,
8 |   PROVIDER_ANALYTICS_RANGES,
9 |   PROVIDER_ANALYTICS_RANGE_LABELS,
10 |   type ProviderAnalyticsRange,
11 | } from "@/lib/provider-analytics";
12 |
13 | type FunnelRow = { id: string; title: string; provider_name: string; eligible_students: number; views: number; saves: number; application_starts: number; provider_clicks: number; outcomes: Record<string, number> };
14 | type Analytics = {
15 |   growth?: { total_registered?: number; wau?: number; mau?: number; returning_users?: number; daily_signups?: { day: string; signups: number }[] };
16 |   activation?: { signups?: number; completed_profiles?: number; viewed_match?: number; activated?: number };
17 |   retention?: { cohort_size?: number; day_1?: number; day_7?: number; day_30?: number };
18 |   demographics?: Record<string, Record<string, number>>;
19 |   acquisition?: { source: string; medium: string; campaign: string; signups: number; completed_profiles: number; activated: number; applications: number }[];
20 |   scholarship_funnel?: FunnelRow[];
21 | };
22 | type VisitorMetric = { day: string; visitors: number; page_views: number };
23 | type VisitorAnalytics = { total_visitors?: number; total_page_views?: number; daily?: VisitorMetric[] };
24 | type ConfirmationEmailAnalytics = {
25 |   summary?: { accepted?: number; failed?: number; confirmed?: number; pending?: number; confirmation_rate?: number };
26 |   daily?: { day: string; accepted: number; failed: number; confirmed: number }[];
27 |   recent?: { id: number; requested_at: string; request_kind: string; request_status: string; email_domain: string; error_code: string | null; confirmed: boolean; confirmed_at: string | null }[];
28 | };
29 |
30 |
31 | const number = (value: number | undefined) => (value ?? 0).toLocaleString();
32 | const rate = (part: number | undefined, whole: number | undefined) => whole ? ${Math.round(((part ?? 0) / whole) * 100)}% : "—";
33 |
34 | function Metric({ label, value, hint }: { label: string; value: string; hint?: string }) {
35 |   return <div className="rounded-xl border border-hairline bg-parchment p-4"><p className="font-mono text-2xl font-semibold text-navy">{value}</p><p className="mt-1 text-xs text-navy-light">{label}</p>{hint && <p className="mt-1 text-[11px] text-navy-light">{hint}</p>}</div>;
36 | }
37 | function Distribution({ title, values }: { title: string; values?: Record<string, number> }) {
38 |   const entries = Object.entries(values ?? {}).sort((a, b) => b[1] - a[1]).slice(0, 8);
39 |   const max = Math.max(1, ...entries.map(([, value]) => value));
40 |   return <div className="rounded-xl border border-hairline bg-white p-5"><h3 className="font-display text-base font-semibold text-navy">{title}</h3><div className="mt-4 space-y-3">{entries.length ? entries.map(([label, value]) => <div key={label}><div className="flex justify-between gap-3 text-xs"><span className="truncate text-ink">{label}</span><span className="font-mono text-navy-light">{value}</span></div><div className="mt-1 h-1.5 rounded-full bg-navy-50"><div className="h-1.5 rounded-full bg-emerald" style={{ width: ${(value / max) * 100}% }} /></div></div>) : <p className="text-sm text-navy-light">No aggregate data in this period.</p>}</div></div>;
41 | }
42 | function PeriodSelector({ selected }: { selected: ProviderAnalyticsRange }) {
43 |   return <div className="flex flex-wrap gap-2" aria-label="Analytics reporting period">{PROVIDER_ANALYTICS_RANGES.map((range) => <Link key={String(range)} href={/admin/analytics?range=${range}} aria-current={range === selected ? "page" : undefined} className={rounded-full border px-3 py-2 text-xs font-medium transition-colors ${range === selected ? "border-navy bg-navy text-white" : "border-hairline bg-white text-navy hover:border-navy"}}>{PROVIDER_ANALYTICS_RANGE_LABELS[range]}</Link>)}</div>;
44 | }
45 |
46 | export default async function ProviderAnalyticsPage({ searchParams }: { searchParams?: { range?: string } }) {
47 |   await requireAdmin();
48 |   const range = parseProviderAnalyticsRange(searchParams?.range);
49 |   const { since, until } = getProviderAnalyticsWindow(range);
50 |   const supabase = createClient();
51 |   const { data, error } = await supabase.rpc("get_provider_analytics", { p_since: since.toISOString(), p_until: until.toISOString(), p_scholarship_id: null });
52 |   const confirmationSince = new Date(since);
53 |   confirmationSince.setDate(confirmationSince.getDate() - 30);
54 |   const [{ data: monitoringLogs, error: monitoringError }, fixLogs, { data: visitorData, error: visitorError }, { data: confirmationData, error: confirmationError }] = await Promise.all([
55 |     supabase.from("monitoring_error_events").select("id, kind, message, source, pathname, digest, created_at").order("created_at", { ascending: false }).limit(200),
56 |     getAutonomousFixLogs(),
57 |     supabase.rpc("get_daily_visitor_metrics", { p_since: since.toISOString(), p_until: until.toISOString() }),
58 |     supabase.rpc("get_auth_confirmation_email_analytics", { p_since: confirmationSince.toISOString(), p_until: until.toISOString() }),
59 |   ]);
60 |   const analytics = (data ?? {}) as Analytics;
61 |   const growth = analytics.growth ?? {};
62 |   const activation = analytics.activation ?? {};
63 |   const retention = analytics.retention ?? {};
64 |   const funnel = analytics.scholarship_funnel ?? [];
65 |   const visitors = (visitorData ?? {}) as VisitorAnalytics;
66 |   const confirmation = (confirmationData ?? {}) as ConfirmationEmailAnalytics;
67 |   const confirmationSummary = confirmation.summary ?? {};
68 |   const dailyVisitors = visitors.daily ?? [];
69 |   const peakVisitors = dailyVisitors.reduce((max, row) => Math.max(max, row.visitors), 0);
70 |   const periodLabel = PROVIDER_ANALYTICS_RANGE_LABELS[range];
71 |   const base = /api/admin/analytics?range=${range};
72 |   return <div>
73 |     <div className="mb-6 flex flex-wrap items-start justify-between gap-4"><div><h1 className="font-display text-2xl font-semibold text-navy">Provider Analytics</h1><p className="mt-1 max-w-2xl text-sm text-navy-light">Aggregate growth, activation, retention, acquisition, and scholarship funnel reporting. No student names, contact details, or individual profiles are exposed.</p></div><div className="flex flex-wrap gap-2 text-xs"><Link href={${base}&report=growth} className="rounded-full border border-hairline bg-white px-3 py-2 text-navy hover:border-navy">Export growth</Link><Link href={${base}&report=funnel} className="rounded-full border border-hairline bg-white px-3 py-2 text-navy hover:border-navy">Export funnel</Link><Link href={${base}&report=retention} className="rounded-full border border-hairline bg-white px-3 py-2 text-navy hover:border-navy">Export retention</Link><Link href={${base}&report=visitors} className="rounded-full border border-emerald bg-emerald-light px-3 py-2 text-emerald hover:border-emerald">Export visitors</Link><Link href={${base}&report=provider} className="rounded-full bg-navy px-3 py-2 text-white hover:bg-navy-light">Export provider report</Link><Link href={${base}&report=fixes} className="rounded-full border border-emerald bg-emerald-light px-3 py-2 text-emerald hover:bg-emerald/15">Export fix logs</Link></div></div>
74 |     <section className="mb-8 rounded-xl border border-hairline bg-parchment p-4"><div className="mb-3 flex flex-wrap items-center justify-between gap-2"><div><p className="text-xs font-semibold uppercase tracking-wide text-navy-light">Reporting period</p><p className="mt-1 text-sm text-navy">Showing statistics for <strong>{periodLabel.toLowerCase()}</strong></p></div><span className="rounded-full bg-white px-3 py-1 text-xs text-navy-light">All sections update together</span></div><PeriodSelector selected={range} /></section>
75 |     {error && <div className="mb-6 rounded-lg bg-rose-light px-4 py-3 text-sm text-rose">Analytics data could not be loaded. Check the database migration and administrator permissions, then try again.</div>}
76 |     <section className="mb-8"><h2 className="mb-3 font-display text-lg font-semibold text-navy">Growth and activation</h2><div className="grid grid-cols-2 gap-3 md:grid-cols-5"><Metric label="Registered users" value={number(growth.total_registered)} /><Metric label="Active users" value={number(growth.mau)} hint={Events in ${periodLabel.toLowerCase()}} /><Metric label="Returning users" value={number(growth.returning_users)} /><Metric label="Activated" value={number(activation.activated)} hint={${rate(activation.activated, activation.signups)} of signups} /><Metric label="Profile completed" value={number(activation.completed_profiles)} hint={${rate(activation.completed_profiles, activation.signups)} of signups} /></div></section>
77 |     <section className="mb-8 rounded-xl border border-hairline bg-white p-5">
78 |       <div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-display text-lg font-semibold text-navy">Confirmation-email delivery funnel</h2><p className="mt-1 max-w-3xl text-sm text-navy-light">Last 30 days of signup and resend requests. “Accepted” means Supabase Auth accepted the request for sending; “Confirmed” is read from the user’s verified account state. Brevo inbox delivery events are not claimed here.</p></div><span className="rounded-full bg-parchment px-3 py-1 text-xs text-navy-light">{confirmationSummary.confirmation_rate ?? 0}% confirmed</span></div>
79 |       {confirmationError ? <p className="mt-4 rounded-lg bg-amber-light px-4 py-3 text-sm text-amber">Confirmation analytics are temporarily unavailable. Check that migration 0103 is applied.</p> : <>
80 |         <div className="mt-4 grid grid-cols-2 gap-3 md:grid-cols-4"><Metric label="Accepted requests" value={number(confirmationSummary.accepted)} /><Metric label="Failed requests" value={number(confirmationSummary.failed)} /><Metric label="Confirmed accounts" value={number(confirmationSummary.confirmed)} /><Metric label="Still pending" value={number(confirmationSummary.pending)} /></div>
81 |         <div className="mt-5 overflow-x-auto"><table className="w-full min-w-[760px] text-left text-sm"><thead><tr className="border-b border-hairline text-xs text-navy-light"><th className="px-3 py-2">Requested</th><th className="px-3 py-2">Type</th><th className="px-3 py-2">Domain</th><th className="px-3 py-2">Request</th><th className="px-3 py-2">Account</th><th className="px-3 py-2">Error</th></tr></thead><tbody>{(confirmation.recent ?? []).map((row) => <tr key={row.id} className="border-b border-hairline last:border-0"><td className="whitespace-nowrap px-3 py-3 text-xs text-navy-light">{new Date(row.requested_at).toLocaleString()}</td><td className="px-3 py-3 capitalize">{row.request_kind}</td><td className="px-3 py-3 text-navy-light">{row.email_domain}</td><td className="px-3 py-3"><span className={rounded-full px-2 py-1 text-xs ${row.request_status === "accepted" ? "bg-emerald-light text-emerald" : "bg-rose-light text-rose"}}>{row.request_status}</span></td><td className="px-3 py-3">{row.confirmed ? <span className="text-emerald">Confirmed</span> : <span className="text-navy-light">Pending</span>}</td><td className="px-3 py-3 text-xs text-rose">{row.error_code ?? "—"}</td></tr>)}</tbody></table>{!(confirmation.recent ?? []).length && <p className="py-5 text-sm text-navy-light">No confirmation requests recorded in this period.</p>}</div>
82 |       </>}
83 |     </section>
84 |     <section className="mb-8 rounded-xl border border-hairline bg-white p-5">
85 |       <div className="flex flex-wrap items-start justify-between gap-3">
86 |         <div><h2 className="font-display text-lg font-semibold text-navy">Daily visitors</h2><p className="mt-1 max-w-2xl text-sm text-navy-light">Unique visitors per UTC day, including public visitors from the new opaque visitor cookie and signed-in visitors from the historical event log. No IP addresses are stored.</p></div>
87 |         <div className="flex gap-2 text-xs"><span className="rounded-full bg-emerald-light px-3 py-1 text-emerald">{number(visitors.total_visitors)} visitors</span><span className="rounded-full bg-parchment px-3 py-1 text-navy-light">{number(visitors.total_page_views)} page views</span></div>
88 |       </div>
89 |       {visitorError ? <p className="mt-4 rounded-lg bg-amber-light px-4 py-3 text-sm text-amber">Visitor metrics are temporarily unavailable.</p> : dailyVisitors.length ? <div className="mt-5 space-y-3">{dailyVisitors.slice(-14).map((row) => <div key={row.day} className="grid grid-cols-[5.5rem_1fr_3rem] items-center gap-3 text-xs"><span className="font-mono text-navy-light">{row.day.slice(5)}</span><div className="h-2 rounded-full bg-navy-50"><div className="h-2 rounded-full bg-emerald" style={{ width: ${Math.max(4, (row.visitors / Math.max(1, peakVisitors)) * 100)}% }} /></div><span className="text-right font-mono text-navy">{row.visitors}</span></div>)}</div> : <p className="mt-5 py-4 text-sm text-navy-light">No visitor data in this period.</p>}
90 |       <p className="mt-4 text-[11px] text-navy-light">Showing the latest 14 days in the chart. Reporting period: {periodLabel.toLowerCase()}.</p>
91 |     </section>
92 |     <section className="mb-8 rounded-xl border border-hairline bg-white p-5"><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-display text-lg font-semibold text-navy">Retention cohorts</h2><p className="mt-1 text-sm text-navy-light">Signup cohort retention uses a returning first-party event in the day-1, day-7, or day-30 window.</p></div><span className="rounded-full bg-amber-light px-3 py-1 text-xs text-amber">Cohort: {number(retention.cohort_size)}</span></div><div className="mt-4 grid grid-cols-3 gap-3 md:max-w-lg"><Metric label="Day 1" value={rate(retention.day_1, retention.cohort_size)} /><Metric label="Day 7" value={rate(retention.day_7, retention.cohort_size)} /><Metric label="Day 30" value={rate(retention.day_30, retention.cohort_size)} /></div></section>
93 |     <section className="mb-8"><h2 className="mb-3 font-display text-lg font-semibold text-navy">Aggregate demographics</h2><div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3"><Distribution title="Institutions" values={analytics.demographics?.institution} /><Distribution title="Disciplines" values={analytics.demographics?.discipline} /><Distribution title="Year level" values={analytics.demographics?.level} /><Distribution title="States" values={analytics.demographics?.state} /><Distribution title="Gender" values={analytics.demographics?.gender} /></div></section>
94 |     <section className="mb-8 rounded-xl border border-hairline bg-white p-5"><h2 className="font-display text-lg font-semibold text-navy">Acquisition performance</h2><p className="mt-1 text-sm text-navy-light">Attribution is stored at signup and shown only as grouped channel totals for {periodLabel.toLowerCase()}.</p><div className="mt-4 overflow-x-auto"><table className="w-full min-w-[720px] text-left text-sm"><thead><tr className="border-b border-hairline text-xs text-navy-light"><th className="px-3 py-2">Source</th><th className="px-3 py-2">Medium</th><th className="px-3 py-2">Campaign</th><th className="px-3 py-2">Signups</th><th className="px-3 py-2">Activated</th><th className="px-3 py-2">Applications</th></tr></thead><tbody>{(analytics.acquisition ?? []).map((row) => <tr key={${row.source}-${row.medium}-${row.campaign}} className="border-b border-hairline last:border-0"><td className="px-3 py-3">{row.source}</td><td className="px-3 py-3 text-navy-light">{row.medium}</td><td className="px-3 py-3 text-navy-light">{row.campaign}</td><td className="px-3 py-3 font-mono">{row.signups}</td><td className="px-3 py-3 font-mono">{row.activated}</td><td className="px-3 py-3 font-mono">{row.applications}</td></tr>)}</tbody></table>{!(analytics.acquisition ?? []).length && <p className="py-6 text-sm text-navy-light">No acquisition data in this period.</p>}</div></section>
95 |     <section className="rounded-xl border border-hairline bg-white p-5"><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-display text-lg font-semibold text-navy">Scholarship funnel</h2><p className="mt-1 text-sm text-navy-light">Eligible students are observed eligible match viewers from the existing match event. Saves and applications use their canonical tables.</p></div><span className="rounded-full bg-emerald-light px-3 py-1 text-xs text-emerald">{funnel.length} scholarships</span></div><div className="mt-4 overflow-x-auto"><table className="w-full min-w-[980px] text-left text-sm"><thead><tr className="border-b border-hairline text-xs text-navy-light"><th className="px-3 py-2">Scholarship</th><th className="px-3 py-2">Eligible</th><th className="px-3 py-2">Viewed</th><th className="px-3 py-2">Saved</th><th className="px-3 py-2">Started</th><th className="px-3 py-2">Provider clicks</th><th className="px-3 py-2">Outcomes</th></tr></thead><tbody>{funnel.map((row) => <tr key={row.id} className="border-b border-hairline last:border-0"><td className="max-w-[280px] px-3 py-3"><p className="truncate font-medium text-ink">{row.title}</p><p className="text-xs text-navy-light">{row.provider_name}</p></td><td className="px-3 py-3 font-mono">{row.eligible_students}</td><td className="px-3 py-3 font-mono">{row.views}</td><td className="px-3 py-3 font-mono">{row.saves}</td><td className="px-3 py-3 font-mono">{row.application_starts}</td><td className="px-3 py-3 font-mono">{row.provider_clicks}</td><td className="px-3 py-3 text-xs text-navy-light">{Object.entries(row.outcomes ?? {}).map(([key, value]) => ${key}: ${value}).join(" · ") || "—"}</td></tr>)}</tbody></table>{!funnel.length && <p className="py-6 text-sm text-navy-light">No scholarship activity in this period.</p>}</div></section>
96 |     <section className="mt-8 rounded-xl border border-hairline bg-white p-5"><div className="flex flex-wrap items-start justify-between gap-3"><div><h2 className="font-display text-lg font-semibold text-navy">Fix history and monitoring logs</h2><p className="mt-1 max-w-3xl text-sm text-navy-light">Read-only operational history: sanitized runtime errors received by Scholars and verified repository commits whose messages identify a fix or repair. Times are shown in your browser locale.</p></div><div className="flex gap-2 text-xs"><span className="rounded-full bg-rose-light px-3 py-1 text-rose">{monitoringLogs?.length ?? 0} recent errors</span><span className="rounded-full bg-emerald-light px-3 py-1 text-emerald">{fixLogs.length} fix commits</span></div></div>{monitoringError ? <p className="mt-4 rounded-lg bg-amber-light px-4 py-3 text-sm text-amber">Runtime error logs are temporarily unavailable.</p> : <div className="mt-4 overflow-x-auto"><table className="w-full min-w-[900px] text-left text-sm"><thead><tr className="border-b border-hairline text-xs text-navy-light"><th className="px-3 py-2">Time</th><th className="px-3 py-2">Status</th><th className="px-3 py-2">Type</th><th className="px-3 py-2">Route</th><th className="px-3 py-2">Message</th><th className="px-3 py-2">Source</th></tr></thead><tbody>{(monitoringLogs ?? []).map((log) => <tr key={log.id} className="border-b border-hairline last:border-0"><td className="whitespace-nowrap px-3 py-3 text-xs text-navy-light">{new Date(log.created_at).toLocaleString()}</td><td className="px-3 py-3"><span className="rounded-full bg-amber-light px-2 py-1 text-xs text-amber">Observed</span></td><td className="whitespace-nowrap px-3 py-3 text-xs font-medium text-rose">{log.kind}</td><td className="max-w-[180px] truncate px-3 py-3 text-xs text-navy-light" title={log.pathname ?? ""}>{log.pathname || "—"}</td><td className="max-w-[360px] truncate px-3 py-3 text-ink" title={log.message}>{log.message}</td><td className="max-w-[180px] truncate px-3 py-3 text-xs text-navy-light" title={log.source ?? ""}>{log.source || "—"}</td></tr>)}</tbody></table>{!monitoringLogs?.length && <p className="py-6 text-sm text-navy-light">No runtime error logs recorded.</p>}</div>}<div className="mt-6 overflow-x-auto"><table className="w-full min-w-[760px] text-left text-sm"><thead><tr className="border-b border-hairline text-xs text-navy-light"><th className="px-3 py-2">Fixed at</th><th className="px-3 py-2">Commit</th><th className="px-3 py-2">Summary</th><th className="px-3 py-2">Author</th></tr></thead><tbody>{fixLogs.map((log) => <tr key={log.sha} className="border-b border-hairline last:border-0"><td className="whitespace-nowrap px-3 py-3 text-xs text-navy-light">{new Date(log.committedAt).toLocaleString()}</td><td className="px-3 py-3"><Link href={log.url} target="_blank" rel="noreferrer" className="font-mono text-xs text-navy hover:underline">{log.shortSha}</Link></td><td className="px-3 py-3 text-ink">{log.message}</td><td className="px-3 py-3 text-xs text-navy-light">{log.author}</td></tr>)}</tbody></table>{!fixLogs.length && <p className="py-6 text-sm text-navy-light">No fix commits were found in the repository history.</p>}</div></section>
97 |   </div>;
98 | }

#####################################################################################
FILE: app/connection-problem/page.tsx
#####################################################################################
STATUS: FOUND
TOTAL LINES: 25
SHA-256: 12af86c6471395bbe1834f85d7bba1614ce65e7b15bbe45f62fd4206463461e0

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 3:
export default function ConnectionProblemPage({

Line 4:
searchParams,

Line 6:
searchParams?: { next?: string | string[] };

Line 8:
const candidate = Array.isArray(searchParams?.next) ? searchParams?.next[0] : searchParams?.next;

COMPLETE SOURCE CODE

1 | import Link from "next/link";
2 |
3 | export default function ConnectionProblemPage({
4 |   searchParams,
5 | }: {
6 |   searchParams?: { next?: string | string[] };
7 | }) {
8 |   const candidate = Array.isArray(searchParams?.next) ? searchParams?.next[0] : searchParams?.next;
9 |   const nextPath = candidate?.startsWith("/") && !candidate.startsWith("//") ? candidate : "/dashboard";
10 |
11 |   return (
12 |     <main className="min-h-[70vh] flex items-center justify-center px-5 py-12">
13 |       <section className="w-full max-w-md rounded-2xl border border-hairline bg-white p-7 text-center shadow-card">
14 |         <p className="text-xs font-semibold uppercase tracking-[0.16em] text-emerald">Connection check</p>
15 |         <h1 className="mt-3 font-display text-2xl font-semibold text-navy">We couldn’t verify your session yet</h1>
16 |         <p className="mt-3 text-sm leading-6 text-navy-light">
17 |           This can happen when the connection is weak. Your session has not been cleared. Check your internet, then try the page again.
18 |         </p>
19 |         <Link href={nextPath} className="mt-6 inline-flex min-h-11 items-center justify-center rounded-seal bg-navy px-5 text-sm font-semibold text-white hover:bg-navy-light">
20 |           Try again
21 |         </Link>
22 |       </section>
23 |     </main>
24 |   );
25 | }

#####################################################################################
FILE: app/resources/[slug]/page.tsx
#####################################################################################
STATUS: FOUND
TOTAL LINES: 75
SHA-256: 6b1da9ab9c9148df8616236b617a5b92b285c221d05b8219faa3857b1e54a8a6

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 0
params.discussionId: 0
params.slug: 2
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 11:
type Props = { params: { slug: string } };

Line 13:
export async function generateMetadata({ params }: Props): Promise<Metadata> {

Line 15:
const result = await getResourceArticleWithRepositoryContent(params.slug);

Line 25:
export default async function ResourceArticlePage({ params }: Props) {

Line 28:
result = await getResourceArticleWithRepositoryContent(params.slug);

COMPLETE SOURCE CODE

1 | import type { Metadata } from "next";
2 | import { notFound } from "next/navigation";
3 | import { Breadcrumbs, SeoJsonLd } from "@/components/SeoJsonLd";
4 | import { Footer } from "@/components/Footer";
5 | import { ResourceArticleBody, extractArticleHeadings } from "@/components/ResourceArticleBody";
6 | import { ArticleTableOfContents, ReadingProgress, ShareArticle } from "@/components/resource-center-interactions";
7 | import { ResourceAdSlot, ResourceCard, ResourceImage, ResourcePageFrame } from "@/components/resource-center";
8 | import { getResourceArticleWithRepositoryContent, getResourceCanonicalUrl, getResourceImageUrl, ResourceDataError } from "@/lib/resource-center";
9 | import Link from "next/link";
10 |
11 | type Props = { params: { slug: string } };
12 |
13 | export async function generateMetadata({ params }: Props): Promise<Metadata> {
14 |   try {
15 |     const result = await getResourceArticleWithRepositoryContent(params.slug);
16 |     if (!result) return { title: "Resource not found" };
17 |     const { article } = result;
18 |     const canonical = getResourceCanonicalUrl(article.slug, article.canonical_url);
19 |     return { title: article.title, description: article.excerpt ?? undefined, alternates: { canonical }, openGraph: { type: "article", title: article.title, description: article.excerpt ?? undefined, url: canonical, publishedTime: article.published_at, modifiedTime: article.last_reviewed_at ?? article.published_at }, twitter: { card: "summary_large_image", title: article.title, description: article.excerpt ?? undefined } };
20 |   } catch {
21 |     return { title: "Resource not found" };
22 |   }
23 | }
24 |
25 | export default async function ResourceArticlePage({ params }: Props) {
26 |   let result;
27 |   try {
28 |     result = await getResourceArticleWithRepositoryContent(params.slug);
29 |   } catch (error) {
30 |     if (error instanceof ResourceDataError) return <ResourcePageFrame><main className="mx-auto max-w-6xl px-6 py-16"><div role="alert" className="rounded-2xl border border-rose/30 bg-white p-8 md:p-12"><p className="font-mono text-xs uppercase tracking-[0.16em] text-rose">A quiet moment</p><h1 className="mt-3 font-display text-3xl font-semibold text-navy">We could not load this guide.</h1><p className="mt-3 max-w-xl text-sm leading-6 text-navy-light">Please try again shortly, or return to the Resource Center.</p><Link href="/resources" className="mt-6 inline-flex rounded-seal bg-navy px-4 py-2.5 text-sm font-semibold text-white hover:bg-navy-light">Back to resources</Link></div></main><Footer /></ResourcePageFrame>;
31 |     throw error;
32 |   }
33 |   if (!result) notFound();
34 |
35 |   const { article, categories, related } = result;
36 |   const canonical = getResourceCanonicalUrl(article.slug, article.canonical_url);
37 |   const base = process.env.NEXT_PUBLIC_APP_URL || "https://www.scholars.com.ng";
38 |   const headings = extractArticleHeadings(article.content_markdown);
39 |   const imageUrl = getResourceImageUrl(article.featured_image_path);
40 |   const breadcrumbItems = [{ name: "Home", href: "/" }, { name: "Resources", href: "/resources" }, ...(categories[0] ? [{ name: categories[0].name, href: /resources/category/${categories[0].slug} }] : []), { name: article.title }];
41 |   const jsonLd = {
42 |     "@context": "https://schema.org",
43 |     "@graph": [
44 |       { "@type": "Article", headline: article.title, description: article.excerpt ?? undefined, mainEntityOfPage: canonical, datePublished: article.published_at, dateModified: article.last_reviewed_at ?? article.published_at, ...(imageUrl ? { image: [imageUrl] } : {}), author: { "@type": "Person", name: article.author_name || "Scholars" }, publisher: { "@type": "Organization", name: "Scholars", url: base } },
45 |       { "@type": "BreadcrumbList", itemListElement: breadcrumbItems.map((item, index) => ({ "@type": "ListItem", position: index + 1, name: item.name, ...(item.href ? { item: ${base}${item.href} } : {}) })) },
46 |     ],
47 |   };
48 |   const formatDate = (value: string) => new Date(value).toLocaleDateString("en-NG", { year: "numeric", month: "long", day: "numeric" });
49 |
50 |   return (
51 |     <ResourcePageFrame>
52 |       <ReadingProgress />
53 |       <SeoJsonLd data={jsonLd} />
54 |       <main>
55 |         <article>
56 |           <header className="border-b border-hairline bg-white">
57 |             <div className="mx-auto max-w-5xl px-6 pb-12 pt-8 md:pb-16 md:pt-12">
58 |               <Breadcrumbs items={breadcrumbItems} />
59 |               <div className="mt-10 max-w-4xl"><div className="flex flex-wrap items-center gap-3 text-[11px] font-semibold uppercase tracking-[0.14em] text-emerald"><span>{article.article_type}</span>{article.reading_time_minutes ? <span className="text-navy-light">{article.reading_time_minutes} min read</span> : null}</div><h1 className="mt-5 font-display text-4xl font-semibold leading-[1.05] text-navy sm:text-6xl">{article.title}</h1>{article.excerpt && <p className="mt-5 max-w-3xl text-lg leading-8 text-navy-light">{article.excerpt}</p>}<div className="mt-7 flex flex-wrap items-center gap-x-5 gap-y-3 text-sm text-navy-light"><span>By <strong className="font-semibold text-navy">{article.author_name || "Scholars"}</strong></span><time dateTime={article.published_at}>{new Date(article.published_at).toLocaleDateString("en-NG", { year: "numeric", month: "long", day: "numeric" })}</time><ShareArticle title={article.title} /></div></div>
60 |             </div>
61 |           </header>
62 |           <div className="mx-auto max-w-5xl px-6 pt-8 md:pt-12">{article.featured_image_path && <ResourceImage path={article.featured_image_path} alt={${article.title} featured image} priority className="aspect-[16/9] w-full rounded-2xl" />}</div>
63 |           <ResourceAdSlot placement="in-article" />
64 |           <div className="mx-auto grid max-w-5xl gap-10 px-6 py-10 md:py-16 lg:grid-cols-[minmax(0,680px)_220px] lg:items-start">
65 |             <div className="min-w-0"><ResourceArticleBody content={article.content_markdown} /><div className="mt-8 border-t border-hairline pt-5 text-sm text-navy-light"><p>Published {formatDate(article.published_at)}.</p>{article.last_reviewed_at && <p>Last reviewed {formatDate(article.last_reviewed_at)}.</p>}</div></div>
66 |             <aside className="space-y-5 lg:sticky lg:top-6"><ArticleTableOfContents headings={headings} /><div className="rounded-2xl border border-hairline bg-white p-5"><p className="font-mono text-[10px] font-semibold uppercase tracking-[0.16em] text-navy-light">About the writer</p><p className="mt-3 font-display text-xl font-semibold text-navy">{article.author_name || "Scholars"}</p>{article.author_bio && <p className="mt-2 text-sm leading-6 text-navy-light">{article.author_bio}</p>}{categories.length > 0 && <div className="mt-6 border-t border-hairline pt-5"><p className="font-mono text-[10px] font-semibold uppercase tracking-[0.16em] text-navy-light">Topics</p><div className="mt-3 flex flex-wrap gap-2">{categories.slice(0, 6).map((category) => <Link key={category.slug} href={/resources/category/${category.slug}} className="rounded-seal bg-navy-50 px-3 py-1.5 text-xs font-medium text-navy hover:bg-emerald-light">{category.name}</Link>)}</div></div>}</div></aside>
67 |           </div>
68 |         </article>
69 |         {related.length > 0 && <section className="border-t border-hairline bg-white"><div className="mx-auto max-w-5xl px-6 py-12 md:py-16"><p className="font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-emerald">Keep reading</p><h2 className="mt-2 font-display text-3xl font-semibold text-navy">More from the desk</h2><div className="mt-6 grid gap-5 md:grid-cols-3">{related.map((item) => <ResourceCard key={item.id} article={item} />)}</div></div></section>}
70 |         <section className="mx-auto max-w-5xl px-6 py-12 md:py-16"><div className="rounded-2xl bg-navy px-6 py-8 text-white md:px-10"><p className="font-mono text-xs font-semibold uppercase tracking-[0.16em] text-emerald-light">Your next move</p><h2 className="mt-3 font-display text-3xl font-semibold">Ready to find the opportunities that fit?</h2><p className="mt-3 max-w-xl text-sm leading-6 text-white/70">Scholars helps students in Nigeria discover verified scholarships and opportunities matched to their profile.</p><Link href="/signup" className="mt-6 inline-flex rounded-seal bg-white px-5 py-3 text-sm font-semibold text-navy hover:bg-parchment">Build your free profile <span aria-hidden="true" className="ml-2">→</span></Link></div></section>
71 |       </main>
72 |       <Footer />
73 |     </ResourcePageFrame>
74 |   );
75 | }

#####################################################################################
FILE: app/resources/category/[slug]/page.tsx
#####################################################################################
STATUS: FOUND
TOTAL LINES: 60
SHA-256: 01988c6d8f63a8e43fb82ada65aa01e553ea785057b372d586f9b252a26ba9f6

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 0
params.discussionId: 0
params.slug: 2
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 9:
type Props = { params: { slug: string } };

Line 11:
export async function generateMetadata({ params }: Props): Promise<Metadata> {

Line 13:
const result = await getResourceCategoryWithRepositoryContent(params.slug);

Line 21:
export default async function ResourceCategoryPage({ params }: Props) {

Line 24:
result = await getResourceCategoryWithRepositoryContent(params.slug);

COMPLETE SOURCE CODE

1 | import Link from "next/link";
2 | import type { Metadata } from "next";
3 | import { notFound } from "next/navigation";
4 | import { Breadcrumbs, SeoJsonLd } from "@/components/SeoJsonLd";
5 | import { Footer } from "@/components/Footer";
6 | import { OpportunityBridge, ResourceAdSlot, ResourceCard, ResourceEmptyState, ResourceErrorState, ResourcePageFrame } from "@/components/resource-center";
7 | import { getResourceCategoryWithRepositoryContent, ResourceDataError } from "@/lib/resource-center";
8 |
9 | type Props = { params: { slug: string } };
10 |
11 | export async function generateMetadata({ params }: Props): Promise<Metadata> {
12 |   try {
13 |     const result = await getResourceCategoryWithRepositoryContent(params.slug);
14 |     if (!result) return { title: "Resource category" };
15 |     return { title: ${result.category.name} resources, description: result.category.description ?? Guides and updates in ${result.category.name}., alternates: { canonical: https://www.scholars.com.ng/resources/category/${result.category.slug} }, openGraph: { title: ${result.category.name} resources, description: result.category.description ?? undefined, url: https://www.scholars.com.ng/resources/category/${result.category.slug}, type: "website" } };
16 |   } catch {
17 |     return { title: "Resource category" };
18 |   }
19 | }
20 |
21 | export default async function ResourceCategoryPage({ params }: Props) {
22 |   let result;
23 |   try {
24 |     result = await getResourceCategoryWithRepositoryContent(params.slug);
25 |   } catch (error) {
26 |     if (error instanceof ResourceDataError) return <ResourcePageFrame><main className="mx-auto max-w-6xl px-6 py-16"><ResourceErrorState /></main><Footer /></ResourcePageFrame>;
27 |     throw error;
28 |   }
29 |   if (!result) notFound();
30 |   const { category, articles, totalCount } = result;
31 |   const base = process.env.NEXT_PUBLIC_APP_URL || "https://www.scholars.com.ng";
32 |   const breadcrumbItems = [{ name: "Home", href: "/" }, { name: "Resources", href: "/resources" }, { name: category.name }];
33 |   const jsonLd = { "@context": "https://schema.org", "@graph": [{ "@type": "CollectionPage", name: ${category.name} resources, description: category.description ?? undefined, url: ${base}/resources/category/${category.slug} }, { "@type": "BreadcrumbList", itemListElement: breadcrumbItems.map((item, index) => ({ "@type": "ListItem", position: index + 1, name: item.name, ...(item.href ? { item: ${base}${item.href} } : {}) })) }] };
34 |   const featured = articles[0];
35 |   const remaining = articles.slice(1);
36 |
37 |   return (
38 |     <ResourcePageFrame>
39 |       <SeoJsonLd data={jsonLd} />
40 |       <main>
41 |         <section className="border-b border-hairline bg-white">
42 |           <div className="mx-auto max-w-6xl px-6 pb-12 pt-8 md:pt-12">
43 |             <Breadcrumbs items={breadcrumbItems} />
44 |             <div className="mt-10 max-w-3xl"><p className="font-mono text-xs font-semibold uppercase tracking-[0.18em] text-emerald">Resource category</p><h1 className="mt-4 font-display text-4xl font-semibold text-navy sm:text-5xl">{category.name}</h1>{category.description && <p className="mt-4 text-base leading-7 text-navy-light">{category.description}</p>}<p className="mt-5 text-sm text-navy-light">{totalCount} eligible {totalCount === 1 ? "guide" : "guides"}</p></div>
45 |           </div>
46 |         </section>
47 |         <section className="mx-auto max-w-6xl px-6 py-10 md:py-14">
48 |           {articles.length === 0 ? <ResourceEmptyState categoryName={category.name} /> : <>
49 |             {featured && <div><p className="mb-4 font-mono text-[11px] font-semibold uppercase tracking-[0.16em] text-emerald">Latest in {category.name}</p><ResourceCard article={featured} featured /></div>}
50 |             {remaining.length > 0 && <div className="mt-12 grid gap-5 md:grid-cols-2 lg:grid-cols-3">{remaining.map((article) => <ResourceCard key={article.id} article={article} />)}</div>}
51 |             <div className="mt-14"><OpportunityBridge /></div>
52 |             <ResourceAdSlot placement="category" />
53 |           </>}
54 |           <Link href="/resources" className="mt-10 inline-flex text-sm font-semibold text-navy hover:underline">← Back to all resources</Link>
55 |         </section>
56 |       </main>
57 |       <Footer />
58 |     </ResourcePageFrame>
59 |   );
60 | }

#####################################################################################
FILE: app/community/contributors/[profileId]/page.tsx
#####################################################################################
STATUS: FOUND
TOTAL LINES: 106
SHA-256: 06f657d3ca0162945a625f82631b9aaee7bed8f6e18ca02ea8276f8e16cb8371

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 2

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 36:
export async function generateMetadata({

Line 37:
params,

Line 39:
params: { profileId: string };

Line 41:
const profile = await loadProfile(params.profileId);

Line 50:
export default async function ContributorProfilePage({

Line 51:
params,

Line 53:
params: { profileId: string };

Line 55:
const profile = await loadProfile(params.profileId);

COMPLETE SOURCE CODE

1 | import type { Metadata } from "next";
2 | import { notFound } from "next/navigation";
3 | import Link from "next/link";
4 | import { createClient } from "@/lib/supabase/server";
5 | import { Avatar } from "@/components/Avatar";
6 |
7 | type ContributorProfile = {
8 |   profile_id: string;
9 |   display_name: string;
10 |   institution_name: string | null;
11 |   bio: string | null;
12 |   community_role: "founder" | "contributor" | "student";
13 |   contribution_count: number;
14 |   avatar_url: string | null;
15 | };
16 |
17 | const ROLE_LABELS: Record<ContributorProfile["community_role"], string> = {
18 |   founder: "Founder",
19 |   contributor: "Contributor",
20 |   student: "Student",
21 | };
22 |
23 | async function loadProfile(profileId: string): Promise<ContributorProfile | null> {
24 |   const supabase = await createClient();
25 |   const { data, error } = await supabase.rpc("get_public_contributor_profile", {
26 |     p_profile_id: profileId,
27 |   });
28 |   if (error) {
29 |     console.error("public_contributor_profile_read_failed", error);
30 |     return null;
31 |   }
32 |   const row = Array.isArray(data) ? data[0] : data;
33 |   return row ? (row as ContributorProfile) : null;
34 | }
35 |
36 | export async function generateMetadata({
37 |   params,
38 | }: {
39 |   params: { profileId: string };
40 | }): Promise<Metadata> {
41 |   const profile = await loadProfile(params.profileId);
42 |   if (!profile) return { title: "Contributor profile | Scholars" };
43 |   return {
44 |     title: ${profile.display_name} | Scholars community,
45 |     description: profile.bio || ${profile.display_name}'s public Scholars community profile.,
46 |     robots: { index: false, follow: false },
47 |   };
48 | }
49 |
50 | export default async function ContributorProfilePage({
51 |   params,
52 | }: {
53 |   params: { profileId: string };
54 | }) {
55 |   const profile = await loadProfile(params.profileId);
56 |   if (!profile) notFound();
57 |
58 |   return (
59 |     <main className="min-h-[100dvh] bg-parchment px-4 py-8 sm:px-6 sm:py-12">
60 |       <div className="mx-auto max-w-xl">
61 |         <Link href="/discover" className="text-sm font-medium text-navy-light hover:text-navy">
62 |           ← Back to Scholars
63 |         </Link>
64 |         <section className="mt-6 rounded-2xl border border-hairline bg-white p-5 shadow-card sm:p-7">
65 |           <div className="flex items-start gap-4">
66 |             <Avatar
67 |               userId={profile.profile_id}
68 |               fullName={profile.display_name}
69 |               avatarUrl={profile.avatar_url}
70 |               size="large"
71 |             />
72 |             <div className="min-w-0">
73 |               <p className="text-xs font-medium uppercase tracking-[0.16em] text-emerald">Community contributor</p>
74 |               <h1 className="mt-1 font-display text-2xl font-semibold text-navy">{profile.display_name}</h1>
75 |               <p className="mt-1 text-sm text-navy-light">
76 |                 {ROLE_LABELS[profile.community_role]} · {profile.contribution_count} {profile.contribution_count === 1 ? "contribution" : "contributions"}
77 |               </p>
78 |             </div>
79 |           </div>
80 |
81 |           <div className="mt-7 space-y-5 border-t border-hairline pt-5">
82 |             {profile.institution_name && (
83 |               <div>
84 |                 <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-emerald">School</p>
85 |                 <p className="mt-1 text-sm leading-relaxed text-ink">{profile.institution_name}</p>
86 |               </div>
87 |             )}
88 |             {profile.bio && (
89 |               <div>
90 |                 <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-emerald">About</p>
91 |                 <p className="mt-1 whitespace-pre-wrap text-sm leading-relaxed text-ink">{profile.bio}</p>
92 |               </div>
93 |             )}
94 |             {!profile.institution_name && !profile.bio && (
95 |               <p className="text-sm leading-relaxed text-navy-light">This contributor has not added school or bio details yet.</p>
96 |             )}
97 |           </div>
98 |
99 |           <p className="mt-7 border-t border-hairline pt-4 text-xs leading-relaxed text-navy-light">
100 |             This profile only shows information the contributor chose to share with the Scholars community. Contact details, academic results, and application information are not shown.
101 |           </p>
102 |         </section>
103 |       </div>
104 |     </main>
105 |   );
106 | }

#####################################################################################
FILE: app/api/admin/discussions/[id]/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 33
SHA-256: f553ed67ca3164709817f07c96f0869bd86316817481168b3e18ee1fc03dea65

PARAMETER OCCURRENCE SUMMARY
params.id: 2
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 15:
export async function PATCH(request: Request, { params }: { params: { id: string } }) {

Line 18:
if (!isUuid(params.id)) return NextResponse.json({ error: "Discussion not found" }, { status: 404 });

Line 27:
.eq("id", params.id)

COMPLETE SOURCE CODE

1 | import { NextResponse } from "next/server";
2 | import { z } from "zod";
3 | import { createClient } from "@/lib/supabase/server";
4 | import { assertAdmin } from "@/lib/admin/guard";
5 | import { checkRateLimit } from "@/lib/ratelimit";
6 | import { dbErrorResponse } from "@/lib/errors";
7 | import { isUuid } from "@/lib/validate";
8 |
9 | const updateSchema = z.object({
10 |   status: z.enum(["published", "hidden"]).optional(),
11 |   is_pinned: z.boolean().optional(),
12 |   is_verified_contributor: z.boolean().optional(),
13 | }).refine((value) => Object.keys(value).length > 0, "No changes supplied");
14 |
15 | export async function PATCH(request: Request, { params }: { params: { id: string } }) {
16 |   const limited = await checkRateLimit(request, { route: "admin-discussion-update", limit: 60 });
17 |   if (limited) return limited;
18 |   if (!isUuid(params.id)) return NextResponse.json({ error: "Discussion not found" }, { status: 404 });
19 |   const supabase = createClient();
20 |   const guard = await assertAdmin(supabase);
21 |   if (!guard.ok) return guard.response;
22 |   const parsed = updateSchema.safeParse(await request.json().catch(() => null));
23 |   if (!parsed.success) return NextResponse.json({ error: "Invalid moderation update" }, { status: 400 });
24 |   const { data, error } = await supabase
25 |     .from("scholarship_discussions")
26 |     .update(parsed.data)
27 |     .eq("id", params.id)
28 |     .select("id, status, is_pinned, is_verified_contributor")
29 |     .maybeSingle();
30 |   if (error) return dbErrorResponse("admin/discussions/update", error);
31 |   if (!data) return NextResponse.json({ error: "Discussion not found" }, { status: 404 });
32 |   return NextResponse.json({ discussion: data });
33 | }

#####################################################################################
FILE: app/api/admin/discussion-reports/[id]/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 36
SHA-256: 46353e6ac73f85bd8ce611a3cf66f172f9233e5eeedecd8029da256a59b3d02b

PARAMETER OCCURRENCE SUMMARY
params.id: 2
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 11:
export async function PATCH(request: Request, { params }: { params: { id: string } }) {

Line 14:
if (!isUuid(params.id)) return NextResponse.json({ error: "Report not found" }, { status: 404 });

Line 23:
.eq("id", params.id)

COMPLETE SOURCE CODE

1 | import { NextResponse } from "next/server";
2 | import { z } from "zod";
3 | import { createClient } from "@/lib/supabase/server";
4 | import { assertAdmin } from "@/lib/admin/guard";
5 | import { checkRateLimit } from "@/lib/ratelimit";
6 | import { dbErrorResponse } from "@/lib/errors";
7 | import { isUuid } from "@/lib/validate";
8 |
9 | const updateSchema = z.object({ status: z.enum(["reviewed", "dismissed", "removed"]) });
10 |
11 | export async function PATCH(request: Request, { params }: { params: { id: string } }) {
12 |   const limited = await checkRateLimit(request, { route: "admin-discussion-report-update", limit: 60 });
13 |   if (limited) return limited;
14 |   if (!isUuid(params.id)) return NextResponse.json({ error: "Report not found" }, { status: 404 });
15 |   const supabase = createClient();
16 |   const guard = await assertAdmin(supabase);
17 |   if (!guard.ok) return guard.response;
18 |   const parsed = updateSchema.safeParse(await request.json().catch(() => null));
19 |   if (!parsed.success) return NextResponse.json({ error: "Invalid report update" }, { status: 400 });
20 |   const { data: report, error: reportError } = await supabase
21 |     .from("scholarship_discussion_reports")
22 |     .update({ status: parsed.data.status, reviewed_by: guard.userId, reviewed_at: new Date().toISOString() })
23 |     .eq("id", params.id)
24 |     .select("id, discussion_id, status, reviewed_at")
25 |     .maybeSingle();
26 |   if (reportError) return dbErrorResponse("admin/discussion-reports/update", reportError);
27 |   if (!report) return NextResponse.json({ error: "Report not found" }, { status: 404 });
28 |   if (parsed.data.status === "removed") {
29 |     const { error: hideError } = await supabase
30 |       .from("scholarship_discussions")
31 |       .update({ status: "hidden" })
32 |       .eq("id", report.discussion_id);
33 |     if (hideError) return dbErrorResponse("admin/discussion-reports/hide", hideError);
34 |   }
35 |   return NextResponse.json({ report });
36 | }

#####################################################################################
FILE: app/api/scholarships/[id]/community/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 138
SHA-256: 7f13829480a8aef05fa92b398bad9f81f664c29e92d57f524a069bf5355bf6f8

PARAMETER OCCURRENCE SUMMARY
params.id: 7
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 22:
export async function GET(

Line 24:
{ params }: { params: { id: string } },

Line 26:
if (!isUuid(params.id)) {

Line 29:
const sort = new URL(request.url).searchParams.get("sort") === "recent" ? "recent" : "helpful";

Line 38:
const community = await loadScholarshipCommunity(supabase, params.id, sort);

Line 44:
export async function POST(

Line 46:
{ params }: { params: { id: string } },

Line 48:
if (!isUuid(params.id)) {

Line 83:
.eq("id", params.id)

Line 97:
if (!parent || parent.scholarship_id !== params.id || parent.status !== "published") {

Line 106:
scholarship_id: params.id,

Line 121:
{ scholarship_id: params.id, category },

COMPLETE SOURCE CODE

1 | import { NextResponse } from "next/server";
2 | import { z } from "zod";
3 | import { createClient } from "@/lib/supabase/server";
4 | import { checkRateLimit } from "@/lib/ratelimit";
5 | import { dbErrorResponse } from "@/lib/errors";
6 | import { isUuid } from "@/lib/validate";
7 | import { loadScholarshipCommunity } from "@/lib/scholarship-community";
8 | import { trackServerEvent } from "@/lib/analytics-server";
9 | import { createServiceClient } from "@/lib/supabase/service";
10 | import { sendPushForProfile } from "@/lib/push/deliver";
11 |
12 | export const dynamic = "force-dynamic";
13 |
14 | const postSchema = z.object({
15 |   category: z.enum(["question", "answer", "experience", "update"]),
16 |   title: z.string().trim().max(140).optional().nullable(),
17 |   body: z.string().trim().min(10).max(2000),
18 |   is_anonymous: z.boolean().default(true),
19 |   parent_id: z.string().uuid().optional().nullable(),
20 | });
21 |
22 | export async function GET(
23 |   request: Request,
24 |   { params }: { params: { id: string } },
25 | ) {
26 |   if (!isUuid(params.id)) {
27 |     return NextResponse.json({ error: "Invalid scholarship id" }, { status: 400 });
28 |   }
29 |   const sort = new URL(request.url).searchParams.get("sort") === "recent" ? "recent" : "helpful";
30 |   const supabase = createClient();
31 |   const {
32 |     data: { user },
33 |     error: authError,
34 |   } = await supabase.auth.getUser();
35 |   if (authError || !user) {
36 |     return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
37 |   }
38 |   const community = await loadScholarshipCommunity(supabase, params.id, sort);
39 |   return NextResponse.json(community, {
40 |     headers: { "Cache-Control": "private, max-age=20, stale-while-revalidate=60" },
41 |   });
42 | }
43 |
44 | export async function POST(
45 |   request: Request,
46 |   { params }: { params: { id: string } },
47 | ) {
48 |   if (!isUuid(params.id)) {
49 |     return NextResponse.json({ error: "Invalid scholarship id" }, { status: 400 });
50 |   }
51 |   const supabase = createClient();
52 |   const {
53 |     data: { user },
54 |     error: authError,
55 |   } = await supabase.auth.getUser();
56 |   if (authError || !user) {
57 |     return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
58 |   }
59 |
60 |   const limited = await checkRateLimit(request, {
61 |     route: "scholarship-discussion-write",
62 |     limit: 15,
63 |     extraKeys: [user:${user.id}],
64 |   });
65 |   if (limited) return limited;
66 |
67 |   const parsed = postSchema.safeParse(await request.json().catch(() => null));
68 |   if (!parsed.success) {
69 |     return NextResponse.json({ error: "Please check the post details", issues: parsed.error.issues }, { status: 400 });
70 |   }
71 |
72 |   const { category, title, body, is_anonymous, parent_id } = parsed.data;
73 |   if (category === "answer" && !parent_id) {
74 |     return NextResponse.json({ error: "An answer needs a discussion to reply to" }, { status: 400 });
75 |   }
76 |   if (category !== "answer" && parent_id) {
77 |     return NextResponse.json({ error: "Only answers can be replies" }, { status: 400 });
78 |   }
79 |
80 |   const { data: scholarship, error: scholarshipError } = await supabase
81 |     .from("scholarships")
82 |     .select("id")
83 |     .eq("id", params.id)
84 |     .eq("verified", true)
85 |     .maybeSingle();
86 |   if (scholarshipError) return dbErrorResponse("scholarship_discussion_scholarship_check", scholarshipError);
87 |   if (!scholarship) return NextResponse.json({ error: "Scholarship not found" }, { status: 404 });
88 |
89 |   let parentAuthorId: string | null = null;
90 |   if (parent_id) {
91 |     const { data: parent, error: parentError } = await supabase
92 |       .from("scholarship_discussions")
93 |       .select("id, scholarship_id, status, author_id")
94 |       .eq("id", parent_id)
95 |       .maybeSingle();
96 |     if (parentError) return dbErrorResponse("scholarship_discussion_parent_check", parentError);
97 |     if (!parent || parent.scholarship_id !== params.id || parent.status !== "published") {
98 |       return NextResponse.json({ error: "That discussion is no longer available" }, { status: 409 });
99 |     }
100 |     parentAuthorId = parent.author_id;
101 |   }
102 |
103 |   const { data, error } = await supabase
104 |     .from("scholarship_discussions")
105 |     .insert({
106 |       scholarship_id: params.id,
107 |       author_id: user.id,
108 |       parent_id: parent_id ?? null,
109 |       category,
110 |       title: title || null,
111 |       body,
112 |       is_anonymous,
113 |     })
114 |     .select("id, scholarship_id, parent_id, category, title, body, is_anonymous, created_at")
115 |     .single();
116 |   if (error) return dbErrorResponse("scholarship_discussions_insert", error);
117 |   trackServerEvent(
118 |     supabase,
119 |     user.id,
120 |     parent_id ? "community_reply_created" : "community_post_created",
121 |     { scholarship_id: params.id, category },
122 |   );
123 |   if (parent_id && parentAuthorId && parentAuthorId !== user.id) {
124 |     try {
125 |       await sendPushForProfile(createServiceClient(), parentAuthorId, {
126 |         title: "You got a reply on Scholars",
127 |         body: "Someone replied to your scholarship community post.",
128 |         data: { url: "/notifications" },
129 |       });
130 |     } catch (pushError) {
131 |       console.warn("community_reply_push_failed", {
132 |         errorName: pushError instanceof Error ? pushError.name : "UnknownError",
133 |       });
134 |     }
135 |   }
136 |
137 |   return NextResponse.json({ discussion: data }, { status: 201 });
138 | }

#####################################################################################
FILE: app/api/discussions/[id]/report/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 34
SHA-256: 3cdb6c9c47b33c37aa8cca2131589a1e7d12a0eb249756894f6e015faeb2ab22

PARAMETER OCCURRENCE SUMMARY
params.id: 3
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 14:
export async function POST(request: Request, { params }: { params: { id: string } }) {

Line 15:
if (!isUuid(params.id)) return NextResponse.json({ error: "Invalid discussion id" }, { status: 400 });

Line 25:
.insert({ discussion_id: params.id, reporter_id: user.id, ...parsed.data })

Line 32:
trackServerEvent(supabase, user.id, "community_reported", { discussion_id: params.id, reason: parsed.data.reason });

COMPLETE SOURCE CODE

1 | import { NextResponse } from "next/server";
2 | import { z } from "zod";
3 | import { createClient } from "@/lib/supabase/server";
4 | import { checkRateLimit } from "@/lib/ratelimit";
5 | import { dbErrorResponse } from "@/lib/errors";
6 | import { isUuid } from "@/lib/validate";
7 | import { trackServerEvent } from "@/lib/analytics-server";
8 |
9 | const reportSchema = z.object({
10 |   reason: z.enum(["misleading", "abusive", "outdated", "personal_information", "spam"]),
11 |   details: z.string().trim().max(500).optional(),
12 | });
13 |
14 | export async function POST(request: Request, { params }: { params: { id: string } }) {
15 |   if (!isUuid(params.id)) return NextResponse.json({ error: "Invalid discussion id" }, { status: 400 });
16 |   const supabase = createClient();
17 |   const { data: { user }, error: authError } = await supabase.auth.getUser();
18 |   if (authError || !user) return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
19 |   const limited = await checkRateLimit(request, { route: "scholarship-discussion-report", limit: 10, extraKeys: [user:${user.id}] });
20 |   if (limited) return limited;
21 |   const parsed = reportSchema.safeParse(await request.json().catch(() => null));
22 |   if (!parsed.success) return NextResponse.json({ error: "Please choose a report reason" }, { status: 400 });
23 |   const { data, error } = await supabase
24 |     .from("scholarship_discussion_reports")
25 |     .insert({ discussion_id: params.id, reporter_id: user.id, ...parsed.data })
26 |     .select("id")
27 |     .single();
28 |   if (error) {
29 |     if (error.code === "23505") return NextResponse.json({ message: "Already reported" });
30 |     return dbErrorResponse("scholarship_discussion_report", error);
31 |   }
32 |   trackServerEvent(supabase, user.id, "community_reported", { discussion_id: params.id, reason: parsed.data.reason });
33 |   return NextResponse.json({ report: data }, { status: 201 });
34 | }

#####################################################################################
FILE: app/api/discussions/[id]/helpful/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 58
SHA-256: 36846d7bfd5ffbbd503fa958ea5013671dd96c52711010815b7f437b74c1ba03

PARAMETER OCCURRENCE SUMMARY
params.id: 6
params.assignmentId: 0
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 19:
export async function POST(request: Request, { params }: { params: { id: string } }) {

Line 20:
if (!isUuid(params.id)) return NextResponse.json({ error: "Invalid discussion id" }, { status: 400 });

Line 25:
.insert({ discussion_id: params.id, profile_id: user.id });

Line 28:
trackServerEvent(supabase, user.id, "community_helpful_reaction", { discussion_id: params.id });

Line 33:
.eq("id", params.id)

Line 51:
export async function DELETE(request: Request, { params }: { params: { id: string } }) {

Line 52:
if (!isUuid(params.id)) return NextResponse.json({ error: "Invalid discussion id" }, { status: 400 });

Line 55:
const { error } = await supabase.from("scholarship_discussion_reactions").delete().eq("discussion_id", params.id).eq("profile_id", user.id);

COMPLETE SOURCE CODE

1 | import { NextResponse } from "next/server";
2 | import { createClient } from "@/lib/supabase/server";
3 | import { checkRateLimit } from "@/lib/ratelimit";
4 | import { dbErrorResponse } from "@/lib/errors";
5 | import { isUuid } from "@/lib/validate";
6 | import { trackServerEvent } from "@/lib/analytics-server";
7 | import { createServiceClient } from "@/lib/supabase/service";
8 | import { sendPushForProfile } from "@/lib/push/deliver";
9 |
10 | async function getUser(request: Request) {
11 |   const supabase = createClient();
12 |   const { data: { user }, error } = await supabase.auth.getUser();
13 |   if (error || !user) return { supabase, user: null, response: NextResponse.json({ error: "Not authenticated" }, { status: 401 }) };
14 |   const limited = await checkRateLimit(request, { route: "scholarship-discussion-helpful", limit: 30, extraKeys: [user:${user.id}] });
15 |   if (limited) return { supabase, user, response: limited };
16 |   return { supabase, user, response: null };
17 | }
18 |
19 | export async function POST(request: Request, { params }: { params: { id: string } }) {
20 |   if (!isUuid(params.id)) return NextResponse.json({ error: "Invalid discussion id" }, { status: 400 });
21 |   const { supabase, user, response } = await getUser(request);
22 |   if (response || !user) return response ?? NextResponse.json({ error: "Not authenticated" }, { status: 401 });
23 |   const { error } = await supabase
24 |     .from("scholarship_discussion_reactions")
25 |     .insert({ discussion_id: params.id, profile_id: user.id });
26 |   if (error && error.code !== "23505") return dbErrorResponse("scholarship_discussion_helpful", error);
27 |   if (!error) {
28 |     trackServerEvent(supabase, user.id, "community_helpful_reaction", { discussion_id: params.id });
29 |     try {
30 |       const { data: discussion } = await supabase
31 |         .from("scholarship_discussions")
32 |         .select("author_id")
33 |         .eq("id", params.id)
34 |         .maybeSingle();
35 |       if (discussion && discussion.author_id !== user.id) {
36 |         await sendPushForProfile(createServiceClient(), discussion.author_id, {
37 |           title: "Your post helped a student",
38 |           body: "Someone marked your scholarship community post as helpful.",
39 |           data: { url: "/notifications" },
40 |         });
41 |       }
42 |     } catch (pushError) {
43 |       console.warn("community_helpful_push_failed", {
44 |         errorName: pushError instanceof Error ? pushError.name : "UnknownError",
45 |       });
46 |     }
47 |   }
48 |   return NextResponse.json({ helpful: true });
49 | }
50 |
51 | export async function DELETE(request: Request, { params }: { params: { id: string } }) {
52 |   if (!isUuid(params.id)) return NextResponse.json({ error: "Invalid discussion id" }, { status: 400 });
53 |   const { supabase, user, response } = await getUser(request);
54 |   if (response || !user) return response ?? NextResponse.json({ error: "Not authenticated" }, { status: 401 });
55 |   const { error } = await supabase.from("scholarship_discussion_reactions").delete().eq("discussion_id", params.id).eq("profile_id", user.id);
56 |   if (error) return dbErrorResponse("scholarship_discussion_helpful_delete", error);
57 |   return NextResponse.json({ helpful: false });
58 | }

#####################################################################################
FILE: app/api/reengagement/click/[assignmentId]/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 35
SHA-256: 0ab65842efa835eeaf028028d536969b0fa787a09d7184e6cd478c773dbea10a

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 1
params.discussionId: 0
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 10:
export async function GET(request: Request, { params }: { params: { assignmentId: string } }) {

Line 17:
.eq('id', params.assignmentId)

Line 32:
destination.searchParams.set('reengagement', '1')

Line 33:
destination.searchParams.set('assignment', assignment.id)

COMPLETE SOURCE CODE

1 | import { NextResponse } from 'next/server'
2 | import { createServiceClient } from '@/lib/supabase/service'
3 | import { checkRateLimit } from '@/lib/ratelimit'
4 |
5 | export const dynamic = 'force-dynamic'
6 |
7 | const BASE_URL = process.env.NEXT_PUBLIC_APP_URL || 'https://scholars-eight.vercel.app'
8 | const ALLOWED_PATHS = new Set(['/onboarding', '/applications', '/dashboard'])
9 |
10 | export async function GET(request: Request, { params }: { params: { assignmentId: string } }) {
11 |   const limited = await checkRateLimit(request, { route: 'reengagement-click', limit: 60 })
12 |   if (limited) return limited
13 |   const service = createServiceClient()
14 |   const { data: assignment, error } = await service
15 |     .from('reengagement_assignments')
16 |     .select('id,experiment_id,deep_link')
17 |     .eq('id', params.assignmentId)
18 |     .maybeSingle()
19 |
20 |   if (error || !assignment || !ALLOWED_PATHS.has(assignment.deep_link)) {
21 |     return NextResponse.redirect(new URL('/dashboard', BASE_URL), 302)
22 |   }
23 |
24 |   await service.from('reengagement_campaign_events').insert({
25 |     experiment_id: assignment.experiment_id,
26 |     assignment_id: assignment.id,
27 |     event: 'clicked',
28 |     meta: { user_agent: request.headers.get('user-agent')?.slice(0, 200) ?? null },
29 |   })
30 |
31 |   const destination = new URL(assignment.deep_link, BASE_URL)
32 |   destination.searchParams.set('reengagement', '1')
33 |   destination.searchParams.set('assignment', assignment.id)
34 |   return NextResponse.redirect(destination, 302)
35 | }

#####################################################################################
FILE: app/api/community/contributors/[discussionId]/route.ts
#####################################################################################
STATUS: FOUND
TOTAL LINES: 26
SHA-256: b02fd04713dd58d000d7775d39a2e66e874508acb7a7b69386c394c78848a5c9

PARAMETER OCCURRENCE SUMMARY
params.id: 0
params.assignmentId: 0
params.discussionId: 1
params.slug: 0
params.profileId: 0

FUNCTION DECLARATIONS AND PARAMETER REFERENCES

Line 6:
type RouteContext = { params: { discussionId: string } };

Line 8:
export async function GET(_request: Request, { params }: RouteContext) {

Line 9:
const discussionId = z.string().uuid().safeParse(params.discussionId);

COMPLETE SOURCE CODE

1 | import { NextResponse } from "next/server";
2 | import { z } from "zod";
3 | import { createClient } from "@/lib/supabase/server";
4 | import { dbErrorResponse } from "@/lib/errors";
5 |
6 | type RouteContext = { params: { discussionId: string } };
7 |
8 | export async function GET(_request: Request, { params }: RouteContext) {
9 |   const discussionId = z.string().uuid().safeParse(params.discussionId);
10 |   if (!discussionId.success) {
11 |     return NextResponse.json({ error: "Invalid discussion" }, { status: 400 });
12 |   }
13 |
14 |   const supabase = await createClient();
15 |   const { data, error } = await supabase.rpc("get_community_contributor_profile", {
16 |     p_discussion_id: discussionId.data,
17 |   });
18 |   if (error) return dbErrorResponse("community_contributor_profile", error);
19 |
20 |   const profile = Array.isArray(data) ? data[0] : data;
21 |   if (!profile) {
22 |     return NextResponse.json({ error: "Contributor profile not available" }, { status: 404 });
23 |   }
24 |
25 |   return NextResponse.json({ profile });
26 | }

=====================================================================================
FINAL SOURCE AUDIT SUMMARY

FILE: app/admin/analytics/page.tsx
STATUS: FOUND
LINES: 98
SHA-256: 210bdfdd64ae91524c7e02c41a7d78f3ab56353c19a77545a66e66b45efa64c0
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/connection-problem/page.tsx
STATUS: FOUND
LINES: 25
SHA-256: 12af86c6471395bbe1834f85d7bba1614ce65e7b15bbe45f62fd4206463461e0
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/resources/[slug]/page.tsx
STATUS: FOUND
LINES: 75
SHA-256: 6b1da9ab9c9148df8616236b617a5b92b285c221d05b8219faa3857b1e54a8a6
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 2, 'params.profileId': 0}

FILE: app/resources/category/[slug]/page.tsx
STATUS: FOUND
LINES: 60
SHA-256: 01988c6d8f63a8e43fb82ada65aa01e553ea785057b372d586f9b252a26ba9f6
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 2, 'params.profileId': 0}

FILE: app/community/contributors/[profileId]/page.tsx
STATUS: FOUND
LINES: 106
SHA-256: 06f657d3ca0162945a625f82631b9aaee7bed8f6e18ca02ea8276f8e16cb8371
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 2}

FILE: app/api/admin/discussions/[id]/route.ts
STATUS: FOUND
LINES: 33
SHA-256: f553ed67ca3164709817f07c96f0869bd86316817481168b3e18ee1fc03dea65
PARAMETER COUNTS: {'params.id': 2, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/api/admin/discussion-reports/[id]/route.ts
STATUS: FOUND
LINES: 36
SHA-256: 46353e6ac73f85bd8ce611a3cf66f172f9233e5eeedecd8029da256a59b3d02b
PARAMETER COUNTS: {'params.id': 2, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/api/scholarships/[id]/community/route.ts
STATUS: FOUND
LINES: 138
SHA-256: 7f13829480a8aef05fa92b398bad9f81f664c29e92d57f524a069bf5355bf6f8
PARAMETER COUNTS: {'params.id': 7, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/api/discussions/[id]/report/route.ts
STATUS: FOUND
LINES: 34
SHA-256: 3cdb6c9c47b33c37aa8cca2131589a1e7d12a0eb249756894f6e015faeb2ab22
PARAMETER COUNTS: {'params.id': 3, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/api/discussions/[id]/helpful/route.ts
STATUS: FOUND
LINES: 58
SHA-256: 36846d7bfd5ffbbd503fa958ea5013671dd96c52711010815b7f437b74c1ba03
PARAMETER COUNTS: {'params.id': 6, 'params.assignmentId': 0, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/api/reengagement/click/[assignmentId]/route.ts
STATUS: FOUND
LINES: 35
SHA-256: 0ab65842efa835eeaf028028d536969b0fa787a09d7184e6cd478c773dbea10a
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 1, 'params.discussionId': 0, 'params.slug': 0, 'params.profileId': 0}

FILE: app/api/community/contributors/[discussionId]/route.ts
STATUS: FOUND
LINES: 26
SHA-256: b02fd04713dd58d000d7775d39a2e66e874508acb7a7b69386c394c78848a5c9
PARAMETER COUNTS: {'params.id': 0, 'params.assignmentId': 0, 'params.discussionId': 1, 'params.slug': 0, 'params.profileId': 0}

Branch inspected: 1c2a92d966447c17bab7a7db38877856bc46f690
Files inspected: 12
GitHub modifications: NONE
Commits created: NONE
Deployments performed: NONE

READ-ONLY AUDIT COMPLETED.