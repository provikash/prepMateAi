# Canonical resume field coverage

All values follow the same pipeline: `SchemaFormSection` writes to
`resumeFormProvider.data`; `ResumeRemoteDataSource.createResume` sends that map
under `data`; `ResumeSerializer` validates and stores it in `Resume.data`;
`prepare_context()` preserves it (normalizing only dates and safe URLs); the
Professional Django template renders it; WeasyPrint consumes that exact HTML.

`[]` denotes a repeatable array item. Lists remain arrays of strings. Every
field below is supported and appears in the Professional PDF when populated.

| Schema section | Field keys (Flutter type) | Saved JSON / renderer context | Professional HTML output | PDF |
|---|---|---|---|---|
| basics | `name`, `label`, `email`, `phone`, `url`, `summary` (String) | `data.basics.<key>` / `resume.basics.<key>` | header, contact row, summary | Yes |
| basics | `location` (Map: `address`, `city`, `region`, `postalCode`, `countryCode`) | `data.basics.location` / `resume.basics.location_label` | contact row | Yes |
| basics | `profiles` (List<Map>: `network`, `username`, `url`) | `data.basics.profiles[]` / `resume.basics.profiles[]` | contact links | Yes |
| work | `name`, `position`, `location`, `summary` (String) | `data.work[].<key>` / `resume.work[].<key>` | Experience entry | Yes |
| work | `url` (String URL) | `data.work[].url` / safe `resume.work[].url` | Experience link | Yes |
| work | `startDate`, `endDate` (String date) | `data.work[].<key>` / `resume.work[].date_range` | Experience dates | Yes |
| work | `highlights` (List<String>) | `data.work[].highlights` / `resume.work[].highlights` | Experience bullets | Yes |
| education | `institution`, `studyType`, `area`, `score`, `location` (String) | `data.education[].<key>` / `resume.education[].<key>` | Education entry | Yes |
| education | `url` (String URL) | `data.education[].url` / safe `resume.education[].url` | Education link | Yes |
| education | `startDate`, `endDate` (String date) | `data.education[].<key>` / `resume.education[].date_range` | Education dates | Yes |
| education | `courses` (List<String>) | `data.education[].courses` / `resume.education[].courses` | Courses row | Yes |
| skills | `name`, `level` (String) | `data.skills[].<key>` / `resume.skills[].<key>` | Skills row | Yes |
| skills | `keywords` (List<String>) | `data.skills[].keywords` / `resume.skills[].keywords` | Skills list | Yes |
| projects | `name`, `description` (String) | `data.projects[].<key>` / `resume.projects[].<key>` | Project entry | Yes |
| projects | `url` (String URL) | `data.projects[].url` / safe `resume.projects[].url` | Project link | Yes |
| projects | `startDate`, `endDate` (String date) | `data.projects[].<key>` / `resume.projects[].date_range` | Project dates | Yes |
| projects | `roles`, `highlights` (List<String>) | `data.projects[].<key>` / `resume.projects[].<key>` | role line and bullets | Yes |
| certificates | `name`, `issuer`, `summary` (String) | `data.certificates[].<key>` / `resume.certificates[].<key>` | Certificate entry | Yes |
| certificates | `date` (String date) | `data.certificates[].date` / `resume.certificates[].date_label` | Certificate date | Yes |
| certificates | `url` (String URL) | `data.certificates[].url` / safe `resume.certificates[].url` | Credential link | Yes |
| languages | `language`, `fluency` (String) | `data.languages[].<key>` / `resume.languages[].<key>` | Languages row | Yes |
| awards | `title`, `awarder`, `summary` (String) | `data.awards[].<key>` / `resume.awards[].<key>` | Award entry | Yes |
| awards | `date` (String date) | `data.awards[].date` / `resume.awards[].date_label` | Award date | Yes |
| volunteer | `organization`, `position`, `summary` (String) | `data.volunteer[].<key>` / `resume.volunteer[].<key>` | Volunteer entry | Yes |
| volunteer | `url` (String URL) | `data.volunteer[].url` / safe `resume.volunteer[].url` | Volunteer link | Yes |
| volunteer | `startDate`, `endDate` (String date) | `data.volunteer[].<key>` / `resume.volunteer[].date_range` | Volunteer dates | Yes |
| volunteer | `highlights` (List<String>) | `data.volunteer[].highlights` / `resume.volunteer[].highlights` | Volunteer bullets | Yes |
| publications | `name`, `publisher`, `summary` (String) | `data.publications[].<key>` / `resume.publications[].<key>` | Publication entry | Yes |
| publications | `releaseDate` (String date) | `data.publications[].releaseDate` / `resume.publications[].date_label` | Publication date | Yes |
| publications | `url` (String URL) | `data.publications[].url` / safe `resume.publications[].url` | Publication link | Yes |
| interests | `name` (String), `keywords` (List<String>) | `data.interests[].<key>` / `resume.interests[].<key>` | Interests row | Yes |
| references | `name`, `reference` (String) | `data.references[].<key>` / `resume.references[].<key>` | Reference entry | Yes |

The three Thomas themes declare the same supported sections in their metadata.
Their placement differs (for example, Navy Sidebar puts education, skills, and
languages in the sidebar), but no canonical field is intentionally unsupported.
