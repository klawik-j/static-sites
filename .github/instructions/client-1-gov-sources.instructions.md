---
applyTo: "sites/client-1/**"
description: "Registry of official legal sources behind the environmental compliance calendar (Hanna Lewandowska ECO ENGINEERING). Internal context — do not publish."
---

# Source registry — environmental compliance calendar (client-1)

**Do not publish.** This file deliberately sits outside `sites/` because
`infra/main.tf` uploads `fileset("../sites/<name>", "**")` in its entirety to the
S3 bucket. Placing it under `sites/client-1/` would publish it on the client's domain.

- **Last full verification:** 2026-09-01
- **Scope:** the `#calendar` section of `sites/client-1/index.html`

---

## Governing principle

The calendar is advisory content published by an environmental compliance
consultancy. A wrong deadline or penalty figure is a reputational and liability
risk for the client. **Never rely on industry blogs, accounting portals, or the
model's own recollection.** Use only acts published in Dziennik Ustaw (Dz.U.) /
Monitor Polski (M.P.) and the websites of public institutions.

---

## Retrieval method — the trap to remember

Source: **Sejm ELI API** — `https://api.sejm.gov.pl/eli/acts/{DU|MP}/{year}/{item}`

> **WARNING — the most common mistake.** The `/text.html` and `/text.pdf`
> endpoints return the **originally promulgated** text, not the consolidated one.
> Reading art. 200 of the Waste Act and art. 92 of the ETS Act from those
> endpoints produced two real errors in this work (a repealed provision and an
> out-of-date deadline).

Correct procedure:

1. `GET /eli/acts/{ELI}` → field `references["Inf. o tekście jednolitym"]` → **latest consolidated text**
2. Download the PDF of **that consolidated text**: `/eli/acts/{ELI_consolidated}/text.pdf`
3. `pdftotext -layout` → flatten with `tr -s ' \n' ' '`
4. Check `references["Akty zmieniające"]` for amendments dated **later than the
   consolidated text** and verify whether they touch the articles of interest
5. Note acts with **deferred entry into force** (`entryIntoForce` in the future)

Metadata: `announcementDate` = date the act was passed/issued, `promulgation` = date published in Dz.U./M.P.

---

## A. Consolidated texts — substantive basis

| Short | Act | Latest consolidated text | Published |
|---|---|---|---|
| `WasteAct` | Act of 14.12.2012 on waste | **Dz.U. 2023 item 1587** | 2023-08-10 |
| `EPL` | Act of 27.04.2001 Environmental Protection Law | **Dz.U. 2025 item 647** | 2025-05-19 |
| `ETS` | Act of 12.06.2015 on the greenhouse gas emission allowance trading scheme | **Dz.U. 2025 item 1685** | 2025-12-03 |
| `PackAct` | Act of 13.06.2013 on packaging and packaging waste management | **Dz.U. 2026 item 619** | 2026-05-08 |
| `EmisMgmt` | Act of 17.07.2009 on the greenhouse gas and other substances emission management system | **Dz.U. 2026 item 526** | 2026-04-16 |
| `CleanAct` | Act of 13.09.1996 on maintaining cleanliness and order in municipalities | **Dz.U. 2025 item 733** | 2025-06-04 |
| `WEEE` | Act of 11.09.2015 on waste electrical and electronic equipment | **Dz.U. 2024 item 573** | 2024-04-15 |
| `BattAct` | Act of 24.04.2009 on batteries and accumulators | **Dz.U. 2025 item 809** | 2025-06-23 |
| `ProdFee` | Act of 11.05.2001 on entrepreneurs' obligations regarding waste management and the product fee | **Dz.U. 2024 item 433** | 2024-03-22 |
| `FGas` | Act of 15.05.2015 on ozone-depleting substances and certain fluorinated greenhouse gases | **Dz.U. 2020 item 2065** | 2020-11-23 |
| `ELV` | Act of 20.01.2005 on the recycling of end-of-life vehicles | **Dz.U. 2020 item 2056** | 2020-11-20 |
| `WaterLaw` | Act of 20.07.2017 Water Law | **Dz.U. 2025 item 960** | — |

## B. Regulations

| Short | Act | Dz.U. | Published |
|---|---|---|---|
| `EmisStd` | Reg. of the Minister of Climate of 24.09.2020 on emission standards | Dz.U. 2020 item 1860 | 2020-10-22 |
| `MeasPres` | Reg. of the Minister of Climate and Environment of 15.12.2020 on types of measurement results and the deadlines and methods of presenting them | Dz.U. 2020 item 2405 | 2020-12-30 |
| `MeasReq` | Reg. of the Minister of Climate and Environment of 7.09.2021 on measurement requirements (consolidated: Dz.U. 2023 item 1706) | Dz.U. 2021 item 1710 | 2021-09-16 |
| `StatProg2026` | Reg. of the Council of Ministers of 16.12.2025 on the public statistics survey programme for 2026 | Dz.U. 2025 item 1842 | 2025-12-23 |

## C. Monitor Polski — annual cycle, re-check every year

| Act | M.P. | Published |
|---|---|---|
| Announcement of the Minister of Climate and Environment of 6.08.2025 on environmental fee rates **for 2026** | **M.P. 2025 item 769** | 2025-08-19 |

Basis: **EPL art. 291(2)** — the minister announces the following year's rates in
M.P. **no later than 31 October each year**.
→ Check for the 2027 announcement after 2026-10-31.

## D. Amendments issued after the consolidated texts — verification status

| Dz.U. | In force from | Finding |
|---|---|---|
| 2026 item 174 | 2026-02-18 | ✔ adds `WasteAct` art. 73(2)(2)(de)/(df) — deposit-return system data |
| 2026 item 875 | **2027-01-01** | ✔ adds `WasteAct` art. 44(4–9) — tacit approval (60 days) for extending a waste collection/processing permit |
| 2026 item 815 | 2026-07-04 | ✔ only `WasteAct` art. 25(6i) — critical infrastructure, no impact on the calendar |
| 2026 item 176 | 2027-02-18 | ✔ Commercial Companies Code omnibus — no impact on reporting deadlines |
| 2025 item 1863 | 2026-01-13 | ✔ CBAM; in the F-gas Act it touches only art. 70 (spending limits) |
| 2025 item 1812 | 2025-12-31 | ✔ does not touch `WasteAct` art. 73–76, 180a |
| 2024 items 1834 / 1911 / 1914 | 2025-01-01 | ✔ as above |

## E. Institutional sources

| Source | Institution | Used for |
|---|---|---|
| `bdo.mos.gov.pl` | IOŚ-PIB / Ministry of Climate and Environment | Reporting channel, announcements, step-by-step guides |

---

## F. OPEN — requires manual verification on EUR-Lex

`eur-lex.europa.eu` blocks automated access (HTTP 202, empty response). The items
below were **not verified at source**. Do not publish dates from this section
without checking them manually.

| Priority | EU act | Question to resolve |
|---|---|---|
| **1** | Reg. (EU) 2025/40 (**PPWR**) | Applies from 12.08.2026. Replaces Dir. 94/62/EC. Does it change packaging reporting duties relative to `PackAct`? |
| **2** | Reg. (EU) 2024/573 (**F-gases**) | Replaced Reg. 517/2014 from 11.03.2024, but `FGas` (2020 consolidated text) still refers to 517/2014. Does the national 28.02 deadline conflict with the EU one? |
| **3** | Reg. (EU) 2023/1542 (**batteries**) | Repealed Dir. 2006/66/EC from 18.08.2025. Do `BattAct` and Reg. 493/2012 still apply? |
| **4** | Commission Reg. (EU) No 493/2012 art. 3(4) | **Confirm the 30.04 deadline** for the battery recycling efficiency report — the only unverified date in the published table |
| **5** | Reg. (EU) 2023/956 (**CBAM**) | Annual declaration deadline under the definitive regime from 2026. Polish implementation: `EmisMgmt` art. 54e–54g, authority: Mazowiecki WIOŚ, penalty EUR 10–50/t |
| 6 | Reg. (EU) 166/2006 (E-PRTR) | Annex I and II thresholds — cited indirectly via EPL art. 236b |

## G. Source categories never queried

- `legislacja.rcl.gov.pl` — pending drafts; needed if an "upcoming changes" section is ever reinstated
- `orzeczenia.nsa.gov.pl` — case law on contested obligations
- Announcements and interpretations from GIOŚ, the Ministry of Climate and Environment, and marshal offices

---

## H. Substantive traps — do not repeat

| Error | Actual position |
|---|---|
| BDO reporting penalty "PLN 500 / 2000 / max 8500" | `WasteAct` **art. 200 is repealed**. **Art. 180a applies — a fine** (petty offence) |
| ETS allowance surrender "30 April" | `ETS` **art. 92(1) — 30 September** (changed by EU Dir. 2023/959) |
| Separate WEEE and battery reports on 15.03 | Abolished — a single report under `WasteAct` art. 73 |
| Semi-annual WEEE reports on 31.07 | Abolished — **zero** occurrences of "31 lipca" or "półrocz" in `WEEE` |
| Municipal waste collectors on 31.07 | `CleanAct` **art. 9n(2) — 31 January**, annually |
| Liquid waste annually on 30.04 | `CleanAct` **art. 9o — quarterly**, by the end of the month following the quarter |
| BDO on 30.09 | One-off COVID extension for FY2019. Statutory date: 15 March |
| Forms `OPAK-1/2/3`, `OŚ-OP1` | Abolished — **zero** occurrences in the 2026 statistics programme (Dz.U. 2025 item 1842) |
| E-PRTR penalty "PLN 5,000–10,000" | EPL **art. 236d**: PLN 200/day (max 365 days); PLN 5,000; PLN 500–25,000 |
| Omitting `WasteAct` art. 74a | Art. 76(1) covers reports under art. 73, **74a** and 75 |
| Omitting the deposit-return system | `PackAct` art. 40o (15.03, BDO) and art. 40p (31.01, municipality) |
| Omitting the Water Law | `WaterLaw` art. 552(2b) — quarterly declarations; art. 552(1) — metering equipment from 31.12.2026 |

---

## I. Legislative inconsistency to flag

EPL **art. 285a(1)** still states **30 April** while cross-referring to `ETS`
art. 92(1), which now says **30 September**. Do not publish that row without
a legal opinion.

---

## J. Verified but deliberately excluded from the published table

The client asked for the "one-off dates and upcoming changes" group to be removed.
The data below is verified and correct — **do not treat its absence as an
oversight, and do not re-add it without asking.**

| Date | Item | Legal basis |
|---|---|---|
| 31.10 annually | Minister announces next year's environmental fee rates in M.P. | EPL art. 291(2) |
| 31.12.2026 | Metering equipment for water abstraction and wastewater discharge becomes mandatory | `WaterLaw` art. 552(1) in conjunction with art. 36 |
| 14.01.2027 | Special deadline for the water services declaration covering Q4 2026 | `WaterLaw` art. 552(2b) |
| 01.01.2027 | Tacit approval after 60 days for extending a waste collection/processing permit | `WasteAct` art. 44(4–9), added by Dz.U. 2026 item 875 |

---

## K. Editorial requirements for the `#calendar` section

- Every row must carry a **legal basis** citing the consolidated text
  (`t.j. Dz.U. 2025 poz. 647`), never the original promulgation address
- The table must display a visible **"Stan prawny na: …"** stamp
- Preserve `data-pl` / `data-en` bilingual attributes in line with the rest of the
  page; the counts of both attributes must match
- Markup contract: `.cal-table` (`min-width: 900px`, scrolls horizontally inside
  `.table-wrap`), group bands use `.cal-table__group-row` with `colspan="5"`,
  legal-basis cells use `.cal-table__legal`, footnotes live in `.cal-notes` with
  the stamp in `.cal-notes__stamp`
- After any revision, update the verification date at the top of this file

### Structure check

```bash
python3 - <<'EOF'
import re
h=open('sites/client-1/index.html',encoding='utf-8').read()
sec=h[h.find('id="calendar"'):h.find('id="contact"')]
rows=re.findall(r'<tr\b[^>]*>(.*?)</tr>', sec, re.S)
bad=[r[:70] for r in rows
     if len(re.findall(r'<t[dh]\b[^>]*>', r)) - len(re.findall(r'colspan=', r))
        + sum(int(m) for m in re.findall(r'colspan="(\d+)"', r)) != 5]
pl=len(re.findall(r'data-pl=',sec)); en=len(re.findall(r'data-en=',sec))
print('rows:',len(rows),'| malformed:',bad or 'none','| data-pl==data-en:',pl==en)
EOF
```

Expected: 36 rows total (1 header + 8 group bands + 27 data rows), no malformed
rows, attribute counts equal.
