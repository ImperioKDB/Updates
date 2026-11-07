# Scholarship revalidation source notes — interim evidence bundle

**Audit snapshot date:** 2026-11-07
**Status:** Partial. Fourteen of seventeen independent record reviews are represented here. The workflow is paused; three reviews remain queued and the reducer has not run.

These notes capture public-source findings for the Scholars Phase 1 data revalidation. They are **not** a final audit, not approved changes, and not evidence that any database correction has been applied. A continuation session must check every source claim against the final workflow output, reconcile all notes with a fresh read-only database snapshot if the date has advanced, resolve conflicts/uncertainties, and produce the complete 11-section report before drawing final counts.

| Record | Note |
|---|---|
| Florence Bamidele Makanjuola Scholarship | [florence.md](./florence.md) |
| JG Afrika Bursary 2027 | [jg-afrika.md](./jg-afrika.md) |
| KPMG Seyi Bickersteth Scholarship Programme | [kpmg.md](./kpmg.md) |
| Lagos State Scholarship Board Bursary & Scholarship Awards | [lagos-state.md](./lagos-state.md) |
| Mastercard Foundation Scholars Program at Pan-Atlantic University | [pau-mastercard.md](./pau-mastercard.md) |
| Midwestern Oil & Gas Host Community Scholarship | [midwestern.md](./midwestern.md) |
| MTN Foundation Science & Technology Scholarship | [mtn.md](./mtn.md) |
| NNPC-Renaissance/TotalEnergies/AENR JV University Scholarship | [nnpc-renaissance.md](./nnpc-renaissance.md) |
| NNPC/Seplat JV National Undergraduate Scholarship | [nnpc-seplat.md](./nnpc-seplat.md) |
| Project 100 for 100 STEM Scholarship | [project-100.md](./project-100.md) |
| PTDF In-Country Undergraduate Scholarship Scheme | [ptdf.md](./ptdf.md) |
| ASUU Scholarship Scheme for Indigent Students | [asuu.md](./asuu.md) |
| Bode Amao Foundation Scholarship | [bode-amao.md](./bode-amao.md) |
| Ejiro M Ukiri International Scholarship Fund | [ejiro.md](./ejiro.md) |

## Still queued in the paused workflow

- Light and Bells Health Foundation Scholarship 2026
- Decagon Undergraduate Honors Program
- NDDC Local Post-Graduate (Master's Degree) Scholarship 2026/2027

The paused workflow is `ee30f0d0dab1`. Continue that job; do not launch a duplicate 17-record workflow. Once the remaining notes are completed, update this manifest and synthesize all 17 results before writing the final audit report.

No production Supabase record, Scholars code, configuration, or deployment was changed during this research.
