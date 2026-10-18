# SATURN X — Script Vault

Responsive Thai script catalog for SATURN X by BM. Buildless HTML, CSS, and JavaScript; publish the `dist/` directory on a static host.

Includes 10 existing SATURN X loaders, text search, category filters, favorites, grid/list layouts, source links, script details, clipboard fallback, and a browser-local personal script collection with add/edit/delete and JSON export/import. Scripts are displayed and copied, never executed by the website. No client secrets or account tokens are included.

Personal scripts and favorites use localStorage on the current browser/origin. They do not sync across devices. Storage failures are reported and failed imports leave the existing collection intact. Export before clearing browser data. Custom scripts are limited to 100 entries and 50,000 characters per script.

Catalog entries are defined in `dist/data.js`; official loaders point at the existing GitHub `main` branch. The catalog does not automatically discover new filenames. New scripts can be added through the website locally, or added to `data.js` and republished to update the shared catalog.

The SVG illustrations are original artwork for this site, not Roblox game screenshots. Google Fonts is optional; system fonts provide the fallback.

Checks: `npm run check` and `npm test`. This environment did not provide the required browser-control capability, so live browser, visual, and clipboard integration checks were not performed. Model tests cover catalog loaders, filtering, import validation, and non-destructive merges; they do not establish Roblox compatibility.
