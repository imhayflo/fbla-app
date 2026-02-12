# Scripts

## Competition scraping

Events are scraped from the official FBLA pages. Any card that says **"resources"** (in its title or category) is **not** added — only real competitions are shown.

- **High School:** https://www.fbla.org/high-school/competitive-events/
- **Middle School:** https://www.fbla.org/middle-school/competitive-events/

For each event we store:

- **Description** – from the event card modal
- **Event Details & Guidelines link** – test competencies PDF (the first link in the modal, shown when you click "Event Details & Guidelines")

Official competition lists (reference PDFs):

- High School: [25-26 High School CE At-A-Glance](https://greektrack-fbla-public.s3.amazonaws.com/files/1/High%20School%20Competitive%20Events%20Resources/25-26-High-School-CE-At-A-Glance.pdf) (or via Connect)
- Middle School: https://www.fbla.org/media/2025/08/25-26-MS-CE-List.pdf

### Run the scraper

From the project root:

```bash
dart run scripts/scrape_competitions.dart
```

Sample output: event counts per level and a few events with description and guidelines URL.

To print a JSON sample:

```bash
dart run scripts/scrape_competitions.dart --json
```

### Inspect raw HTML (one page)

```bash
dart run scripts/fetch_fbla_html.dart
```

This fetches the high school page and prints one parsed event (name, description, guidelines URL).
