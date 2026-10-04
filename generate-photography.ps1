$ErrorActionPreference = 'Stop'

$photoDirectory = Join-Path $PSScriptRoot 'pics/photos'
$outputFile = Join-Path $PSScriptRoot 'photography.html'

if (-not (Test-Path -Path $photoDirectory -PathType Container)) {
    throw "Photo directory not found: $photoDirectory"
}

Add-Type -AssemblyName System.Drawing

function Get-PhotoCaptureTime {
  param([System.IO.FileInfo]$Photo)

  $image = $null
  try {
    $image = [System.Drawing.Image]::FromFile($Photo.FullName)
    $dateTaken = [System.Text.Encoding]::ASCII.GetString(
      $image.GetPropertyItem(0x9003).Value
    ).Trim([char]0)

    return [datetime]::ParseExact(
      $dateTaken,
      'yyyy:MM:dd HH:mm:ss',
      [System.Globalization.CultureInfo]::InvariantCulture
    )
  }
  catch {
    return $Photo.CreationTime
  }
  finally {
    if ($null -ne $image) {
      $image.Dispose()
    }
  }
}

function Get-PhotoCategory {
  param([string[]]$Keywords)

  $keywordSet = @{}
  foreach ($keyword in ($Keywords | Where-Object { $_ })) {
    $keywordSet[$keyword.ToLowerInvariant()] = $true
  }

  $categoryRules = [ordered]@{
    'Birds' = @('bird')
    'Mammals' = @('mammal', 'coyote', 'deer', 'douglas squirrel', 'eastern cottontail')
    'Reptiles & Amphibians' = @('reptile', 'amphibian')
    'Invertebrates' = @('invertebrate', 'insect', 'arachnid')
    'People' = @('people', 'person', 'portrait')
    'Places' = @('place', 'landscape', 'cityscape')
  }

  foreach ($category in $categoryRules.Keys) {
    foreach ($categoryKeyword in $categoryRules[$category]) {
      if ($keywordSet.ContainsKey($categoryKeyword)) {
        return $category
      }
    }
  }

  return 'Other'
}

function Get-PhotoLabel {
  param(
    [System.IO.FileInfo]$Photo,
    [string[]]$Keywords,
    [string]$Category
  )

  $excludedKeywords = @(
    'animal', 'bird', 'place', 'mammal', 'reptile', 'amphibian',
    'invertebrate', 'insect', 'arachnid', 'people', 'person', 'portrait',
    'landscape', 'cityscape', 'changed', 'cr3', 'environment', 'exported'
  )

  if ($Category -in @('Birds', 'Mammals', 'Reptiles & Amphibians', 'Invertebrates')) {
    $excludedKeywords += @(
      'anacortes', 'back yard', 'carkeek park', 'crescent beach', 'front yard',
      'juanita bay park', 'north shore preserve', 'riverside business park',
      'smith island habitat & wildlife viewing area', 'union bay natural area',
      'warren g magnuson park', 'washington park arboretum', 'yesler swamp'
    )
  }

  $label = $Keywords |
    Where-Object { $_ -and $_.ToLowerInvariant() -notin $excludedKeywords } |
    Select-Object -First 1

  if ($label) {
    return (Get-Culture).TextInfo.ToTitleCase($label.ToLowerInvariant())
  }

  return [System.IO.Path]::GetFileNameWithoutExtension($Photo.Name)
}

$shell = New-Object -ComObject Shell.Application
$shellFolder = $shell.Namespace($photoDirectory)

$photos = Get-ChildItem -Path $photoDirectory -File |
    Where-Object { $_.Extension -match '^(?i)\.(jpg|jpeg|png)$' } |
    ForEach-Object {
      $shellItem = $shellFolder.ParseName($_.Name)
      $keywords = @($shellItem.ExtendedProperty('System.Keywords')) |
        Where-Object { $_ -is [string] -and -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() }
      $category = Get-PhotoCategory $keywords

      [pscustomobject]@{
        File = $_
        CaptureTime = Get-PhotoCaptureTime $_
        Keywords = $keywords
        Category = $category
        Label = Get-PhotoLabel $_ $keywords $category
      }
    } |
    Sort-Object `
      @{ Expression = { $_.CaptureTime }; Descending = $true },
      @{ Expression = { $_.File.Name }; Descending = $true }

$categoryOrder = @('Birds', 'Mammals', 'Reptiles & Amphibians', 'Invertebrates', 'People', 'Places', 'Other')
$categoryCounts = @{}
foreach ($category in $categoryOrder) {
  $categoryCounts[$category] = @($photos | Where-Object { $_.Category -eq $category }).Count
}

$categoryButtons = @(
  "          <button aria-pressed=`"true`" class=`"is-active`" data-category=`"all`" type=`"button`">All <span>$($photos.Count)</span></button>"
)
foreach ($category in $categoryOrder) {
  if ($categoryCounts[$category] -gt 0) {
    $encodedCategory = [System.Net.WebUtility]::HtmlEncode($category)
    $categorySlug = $category.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $categoryButtons += "          <button aria-pressed=`"false`" data-category=`"$categorySlug`" type=`"button`">$encodedCategory <span>$($categoryCounts[$category])</span></button>"
  }
}

$galleryItems = foreach ($photo in $photos) {
    $relativePath = "pics/photos/$($photo.File.Name)"
    $categorySlug = $photo.Category.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $encodedLabel = [System.Net.WebUtility]::HtmlEncode($photo.Label)
    "          <a data-category=`"$categorySlug`" data-label=`"$encodedLabel`" href=`"$relativePath`"><img src=`"$relativePath`" alt=`"$encodedLabel`" loading=`"lazy`"></a>"
}

$document = @"
<!DOCTYPE html>
<html>
  <head>
    <link rel="icon" href="https://cdn.iconscout.com/icon/premium/png-512-thumb/physics-1829778-1551933.png">
    <meta name="robots" content="index,follow">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1">
    <meta content="Brandon N. Benton" name="author">
    <title>Brandon N. Benton - Photography</title>
    <meta name="description" content="Photography by Brandon N. Benton.">
    <link href="http://fonts.googleapis.com/css?family=Titillium+Web:400,700" rel="stylesheet" type="text/css">
    <link rel="stylesheet" type="text/css" href="css/main.css">
    <style>
      #photography-content { margin: 34px auto; max-width: 1400px; padding: 0 24px; }
      #photography-content h1 { position: static; margin: 0 0 22px; padding: 0; }
      .gallery-layout { background: #080808; color: #f5f5f2; display: grid; grid-template-columns: 190px minmax(0, 1fr); min-height: 70vh; padding: 28px; }
      .category-nav { align-content: start; display: grid; gap: 3px; padding-right: 28px; }
      .category-nav button { background: transparent; border: 0; color: #aaa; cursor: pointer; font: 16px/1.3 'Titillium Web', sans-serif; padding: 7px 0; text-align: left; }
      .category-nav button:hover, .category-nav button:focus-visible, .category-nav button.is-active { color: white; }
      .category-nav button.is-active { font-weight: 700; }
      .category-nav span { color: #666; float: right; font-size: 13px; }
      .photo-gallery { display: grid; gap: 5px; grid-auto-flow: dense; grid-template-columns: repeat(auto-fill, minmax(210px, 1fr)); }
      .photo-gallery a { background: #171717; display: block; aspect-ratio: 4 / 3; overflow: hidden; }
      .photo-gallery a[hidden] { display: none; }
      .photo-gallery img { display: block; width: 100%; height: 100%; object-fit: cover; opacity: 0; transition: opacity 0.25s ease, transform 0.25s ease; }
      .photo-gallery img.is-loaded { opacity: 1; }
      .photo-gallery a:hover img { transform: scale(1.025); }
      .lightbox { align-items: center; background: rgba(0, 0, 0, 0.9); display: none; inset: 0; justify-content: center; overflow: auto; position: fixed; z-index: 2; }
      .lightbox.is-open { display: flex; }
      .lightbox-figure { margin: 0; text-align: center; }
      .lightbox img { cursor: zoom-in; max-height: 82vh; max-width: 88vw; object-fit: contain; }
      .lightbox figcaption { color: white; font: 18px/1.4 'Titillium Web', sans-serif; margin-top: 10px; }
      .lightbox-count { color: #999; display: block; font-size: 13px; margin-top: 2px; }
      .lightbox.is-zoomed { align-items: flex-start; justify-content: flex-start; padding: 24px; }
      .lightbox.is-zoomed img { cursor: zoom-out; max-height: none; max-width: none; }
      .lightbox button { background: transparent; border: 0; color: white; cursor: pointer; font-size: 42px; line-height: 1; padding: 16px; position: fixed; }
      .lightbox-close { right: 16px; top: 16px; }
      .lightbox-previous { left: 16px; top: 50%; transform: translateY(-50%); }
      .lightbox-next { right: 16px; top: 50%; transform: translateY(-50%); }
      @media (max-width: 700px) {
        #photography-content { padding: 0 12px; }
        .gallery-layout { grid-template-columns: 1fr; padding: 16px; }
        .category-nav { display: flex; gap: 18px; overflow-x: auto; padding: 0 0 16px; white-space: nowrap; }
        .category-nav button { flex: 0 0 auto; }
        .category-nav span { float: none; margin-left: 4px; }
        .photo-gallery { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      }
    </style>
  </head>
  <body>
    <div id="wrapper">
      <ul id="navbar">
        <li><a href="index.html">Home</a></li>
        <li><a href="research.html">Research</a></li>
        <li><a href="projects.html">Side Projects</a></li>
        <li><a href="teaching.html">Teaching</a></li>
        <!--<li><a href="hobbies.html">Hobbies</a></li>-->
        <li><a href="photography.html">Photography</a></li>
      </ul>
    </div>
    <main id="photography-content">
      <h1>Photography</h1>
      <div class="gallery-layout">
        <nav aria-label="Photo categories" class="category-nav">
$($categoryButtons -join "`r`n")
        </nav>
        <div class="photo-gallery">
$($galleryItems -join "`r`n")
        </div>
      </div>
    </main>
    <div class="lightbox" aria-hidden="true" id="lightbox">
      <button aria-label="Close photo" class="lightbox-close" type="button">&times;</button>
      <button aria-label="Previous photo" class="lightbox-previous" type="button">&larr;</button>
      <figure class="lightbox-figure">
        <img alt="" id="lightbox-image" tabindex="0">
        <figcaption><span id="lightbox-label"></span><span class="lightbox-count" id="lightbox-count"></span></figcaption>
      </figure>
      <button aria-label="Next photo" class="lightbox-next" type="button">&rarr;</button>
    </div>
    <script>
      const galleryLinks = Array.from(document.querySelectorAll('.photo-gallery a'));
      const categoryButtons = Array.from(document.querySelectorAll('.category-nav button'));
      const lightbox = document.getElementById('lightbox');
      const lightboxImage = document.getElementById('lightbox-image');
      const lightboxLabel = document.getElementById('lightbox-label');
      const lightboxCount = document.getElementById('lightbox-count');
      let visibleGalleryLinks = galleryLinks;
      let activePhoto = 0;

      function showPhoto(index) {
        activePhoto = (index + visibleGalleryLinks.length) % visibleGalleryLinks.length;
        const photo = visibleGalleryLinks[activePhoto];
        lightbox.classList.remove('is-zoomed');
        lightboxImage.src = photo.href;
        lightboxImage.alt = photo.dataset.label;
        lightboxLabel.textContent = photo.dataset.label;
        lightboxCount.textContent = (activePhoto + 1) + ' of ' + visibleGalleryLinks.length;
      }

      function openLightbox(index) {
        showPhoto(index);
        lightbox.classList.add('is-open');
        lightbox.setAttribute('aria-hidden', 'false');
      }

      function closeLightbox() {
        lightbox.classList.remove('is-open');
        lightbox.setAttribute('aria-hidden', 'true');
      }

      function selectCategory(category) {
        visibleGalleryLinks = galleryLinks.filter((link) => category === 'all' || link.dataset.category === category);
        galleryLinks.forEach((link) => {
          link.hidden = !visibleGalleryLinks.includes(link);
        });
        categoryButtons.forEach((button) => {
          const isActive = button.dataset.category === category;
          button.classList.toggle('is-active', isActive);
          button.setAttribute('aria-pressed', isActive.toString());
        });
      }

      galleryLinks.forEach((link) => {
        link.addEventListener('click', (event) => {
          event.preventDefault();
          openLightbox(visibleGalleryLinks.indexOf(link));
        });
        const image = link.querySelector('img');
        if (image.complete) image.classList.add('is-loaded');
        image.addEventListener('load', () => image.classList.add('is-loaded'));
      });

      categoryButtons.forEach((button) => {
        button.addEventListener('click', () => {
          selectCategory(button.dataset.category);
        });
      });

      document.querySelector('.lightbox-close').addEventListener('click', closeLightbox);
      document.querySelector('.lightbox-previous').addEventListener('click', () => showPhoto(activePhoto - 1));
      document.querySelector('.lightbox-next').addEventListener('click', () => showPhoto(activePhoto + 1));
      function toggleZoom() {
        lightbox.classList.toggle('is-zoomed');
      }

      lightboxImage.addEventListener('click', toggleZoom);
      lightboxImage.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          toggleZoom();
        }
      });
      lightbox.addEventListener('click', (event) => {
        if (event.target === lightbox) closeLightbox();
      });
      document.addEventListener('keydown', (event) => {
        if (!lightbox.classList.contains('is-open')) return;
        if (event.key === 'ArrowLeft') showPhoto(activePhoto - 1);
        if (event.key === 'ArrowRight') showPhoto(activePhoto + 1);
        if (event.key === 'Escape') closeLightbox();
      });
    </script>
  </body>
</html>
"@

Set-Content -Path $outputFile -Value $document -Encoding ascii