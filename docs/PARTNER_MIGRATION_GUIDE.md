# Partner Migration Guide: Changing Partner Slug

This guide documents the complete process for migrating a partner from one slug to another (e.g., `deveho-consulting` → `todis-consulting`).

## Overview
This migration involves updating:
- File system directories and files
- Configuration files
- SEO content and metadata
- Database records
- Build scripts and routing

## Prerequisites
- Development server should be running
- Git repository should be clean (commit any pending changes)
- Database access to update partner records

## Step-by-Step Migration Process

### 1. Search for All Occurrences
First, identify all places where the old slug is referenced:

```bash
# Search for the old slug in the entire project
grep -r "old-slug" /path/to/project --exclude-dir=node_modules --exclude-dir=.git
```

Expected locations:
- Configuration files (`vite.config.ts`, `serve.json`)
- Build scripts (`scripts/generate-*.ts`)
- SEO plugin configuration (`vite-seo-plugin.ts`)
- SEO content files (`public/seo/`)
- Directory names (`partnerzy/`, `public/seo/partnerzy/`)

### 2. Update Configuration Files

#### 2.1 Update `vite.config.ts`
```typescript
// Change the alias name and path
// FROM:
oldslug: resolve(__dirname, 'partnerzy/old-slug/index.html'),
// TO:
newslug: resolve(__dirname, 'partnerzy/new-slug/index.html'),
```

#### 2.2 Update `scripts/generate-partner-pages.ts`
```typescript
// Update the PARTNER_SLUGS array
const PARTNER_SLUGS = [
  // ... other slugs
  'new-slug', // Changed from 'old-slug'
  // ... other slugs
];
```

#### 2.3 Update `scripts/generate-sitemap.ts`
```typescript
// Update the partners array
const partners = [
  // ... other partners
  'new-slug', // Changed from 'old-slug'
  // ... other partners
];
```

#### 2.4 Update `vite-seo-plugin.ts`
```typescript
// Update the PARTNER_SLUGS array
const PARTNER_SLUGS = [
  // ... other slugs
  'new-slug', // Changed from 'old-slug'
  // ... other slugs
];
```

#### 2.5 Update `serve.json`
```json
{
  "source": "/partnerzy/new-slug",
  "destination": "/partnerzy/new-slug/index.html"
}
```

### 3. Update SEO Content Files

#### 3.1 Update Partner SEO File
File: `public/seo/partnerzy/old-slug/index.html`
```html
<!-- Update canonical URL -->
<link rel="canonical" href="https://www.raport-erp.pl/partnerzy/new-slug">

<!-- Update structured data URL -->
"url": "https://www.raport-erp.pl/partnerzy/new-slug",

<!-- Update company name if needed -->
"name": "New Company Name",
<title>New Company Name | Partner Raportu ERP by ERP-VIEW.PL</title>
<meta name="description" content="Poznaj New Company Name - partnera Raportu ERP...">
<meta name="keywords" content="partner erp, wdrożenie erp, New Company Name, systemy erp, implementacja erp">
```

#### 3.2 Update Partner Index SEO File
File: `public/seo/partnerzy/index.html`
```html
<!-- Update partner listing -->
"url": "https://www.raport-erp.pl/partnerzy/new-slug"
"name": "New Company Name",
```

#### 3.3 Update Company Listing SEO File
File: `public/seo/firmy-it/index.html`
```html
<!-- Update company references -->
"name": "New Company Name",
"url": "https://www.raport-erp.pl/firmy-it/new-company-slug",
```

#### 3.4 Update System SEO Files (if applicable)
Check files like `public/seo/systemy-erp/*/index.html` for company references:
```html
<!-- Update company name in keywords and publisher -->
<meta name="keywords" content="..., New Company Name, ...">
"publisher": {
  "@type": "Organization",
  "name": "New Company Name"
}
```

### 4. Rename Directories and Files

#### 4.1 Rename Main Partner Directory
```bash
mv partnerzy/old-slug partnerzy/new-slug
```

#### 4.2 Rename SEO Directory
```bash
mv public/seo/partnerzy/old-slug public/seo/partnerzy/new-slug
```

#### 4.3 Clean Up Build Artifacts
```bash
# Remove any cached build files
rm -rf dist/partnerzy/old-slug
rm -rf dist/public/seo/partnerzy/old-slug
rm -rf dist/seo/partnerzy/old-slug
# Or simply remove entire dist directory
rm -rf dist
```

### 5. Update Database Records

**CRITICAL:** Update the partner record in the database:
```sql
-- Update the partner slug in the database
UPDATE partners 
SET slug = 'new-slug' 
WHERE slug = 'old-slug';

-- Also update any related tables if necessary
UPDATE partner_pages 
SET slug = 'new-slug' 
WHERE slug = 'old-slug';
```

### 6. Restart Development Server

```bash
# Kill existing server
pkill -f "npm run dev"
# or
pkill -f "vite"

# Start fresh server
npm run dev
```

### 7. Verification Steps

#### 7.1 Check for Remaining References
```bash
# Should return no results
grep -r "old-slug" /path/to/project --exclude-dir=node_modules --exclude-dir=.git
```

#### 7.2 Test URLs
- ✅ New URL should work: `http://localhost:5173/partnerzy/new-slug`
- ❌ Old URL should return 404: `http://localhost:5173/partnerzy/old-slug`

#### 7.3 Check Server Logs
- No errors about missing directories
- SEO plugin should load without errors

### 8. Commit and Push Changes

```bash
# Add all changes
git add .

# Check what will be committed
git status

# Commit with descriptive message
git commit -m "Migrate partner from old-slug to new-slug

- Rename directories: partnerzy/old-slug -> partnerzy/new-slug
- Rename SEO directories: public/seo/partnerzy/old-slug -> public/seo/partnerzy/new-slug
- Update all configuration files (vite.config.ts, scripts, serve.json)
- Update SEO content and company name references
- Update partner slug references in all build scripts"

# Push to remote repository
git push origin main
```

## Common Issues and Solutions

### Issue 1: Old URL Still Accessible
**Cause:** Database still contains old slug
**Solution:** Update database records (Step 5)

### Issue 2: SEO Plugin Errors
**Cause:** Plugin trying to access old directory
**Solution:** Restart development server and clear dist directory

### Issue 3: Build Errors
**Cause:** Configuration files still reference old paths
**Solution:** Double-check all configuration files (Step 2)

## Files That Need Updates

### Configuration Files
- `vite.config.ts`
- `scripts/generate-partner-pages.ts`
- `scripts/generate-sitemap.ts`
- `vite-seo-plugin.ts`
- `serve.json`

### SEO Content Files
- `public/seo/partnerzy/[old-slug]/index.html`
- `public/seo/partnerzy/index.html`
- `public/seo/firmy-it/index.html`
- `public/seo/systemy-erp/*/index.html` (if company is referenced)

### Directory Structure
- `partnerzy/[old-slug]/` → `partnerzy/[new-slug]/`
- `public/seo/partnerzy/[old-slug]/` → `public/seo/partnerzy/[new-slug]/`

### Database Tables
- `partners` table (slug column)
- `partner_pages` table (if exists)

## Checklist

- [ ] Search for all occurrences of old slug
- [ ] Update `vite.config.ts` alias
- [ ] Update `scripts/generate-partner-pages.ts`
- [ ] Update `scripts/generate-sitemap.ts`
- [ ] Update `vite-seo-plugin.ts`
- [ ] Update `serve.json` routing
- [ ] Update partner SEO file content
- [ ] Update partner index SEO file
- [ ] Update company listing SEO file
- [ ] Update system SEO files (if applicable)
- [ ] Rename main partner directory
- [ ] Rename SEO directory
- [ ] Clean up build artifacts
- [ ] Update database records
- [ ] Restart development server
- [ ] Verify no remaining references
- [ ] Test new URL works
- [ ] Test old URL returns 404
- [ ] Check server logs for errors
- [ ] Commit changes
- [ ] Push to GitHub

## Notes

- Always update the database slug AFTER making file system changes
- The SEO plugin dynamically generates routes based on database entries
- Restart the development server after making configuration changes
- Clear the dist directory to remove cached build files
- Test thoroughly before pushing to production
