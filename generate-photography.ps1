$photoDirectory = Join-Path $PSScriptRoot 'pics/photos'
$outputFile = Join-Path $PSScriptRoot 'photography.html'

if (-not (Test-Path -Path $photoDirectory -PathType Container)) {
    throw "Photo directory not found: $photoDirectory"
}

$photos = Get-ChildItem -Path $photoDirectory -File |
    Where-Object { $_.Extension -match '^(?i)\.(jpg|jpeg|png)$' } |
    Sort-Object Name

$galleryItems = foreach ($photo in $photos) {
    $relativePath = "pics/photos/$($photo.Name)"
    "        <a href=`"$relativePath`"><img src=`"$relativePath`" alt=`"Photograph by Brandon Benton`"></a>"
}

$document = @"
<!DOCTYPE html>
<html>
  <head>
    <link rel="icon" href="https://cdn.iconscout.com/icon/premium/png-512-thumb/physics-1829778-1551933.png">
    <meta name="robots" content="index,follow">
    <meta http-equiv="Content-Type" content="text/html;charset=iso-8859-1">
    <meta content="Brandon N. Benton" name="author">
    <title>Brandon N. Benton - Photography</title>
    <meta name="description" content="Photography by Brandon N. Benton.">
    <link href="http://fonts.googleapis.com/css?family=Titillium+Web:400,700" rel="stylesheet" type="text/css">
    <link rel="stylesheet" type="text/css" href="css/main.css">
    <style>
      #photography-content { margin: 50px auto; max-width: 1200px; padding: 0 24px; }
      #photography-content h1 { position: static; margin: 0 0 28px; padding: 0; }
      .photo-gallery { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; }
      .photo-gallery a { display: block; aspect-ratio: 4 / 3; overflow: hidden; }
      .photo-gallery img { display: block; width: 100%; height: 100%; object-fit: cover; transition: transform 0.2s ease; }
      .photo-gallery a:hover img { transform: scale(1.04); }
      .lightbox { align-items: center; background: rgba(0, 0, 0, 0.9); display: none; inset: 0; justify-content: center; position: fixed; z-index: 2; }
      .lightbox.is-open { display: flex; }
      .lightbox img { max-height: 88vh; max-width: 88vw; object-fit: contain; }
      .lightbox button { background: transparent; border: 0; color: white; cursor: pointer; font-size: 42px; line-height: 1; padding: 16px; position: fixed; }
      .lightbox-close { right: 16px; top: 16px; }
      .lightbox-previous { left: 16px; top: 50%; transform: translateY(-50%); }
      .lightbox-next { right: 16px; top: 50%; transform: translateY(-50%); }
    </style>
  </head>
  <body>
    <div id="wrapper">
      <ul id="navbar">
        <li><a href="about.html">About Me</a></li>
        <li><a href="research.html">Research</a></li>
        <li><a href="projects.html">Side Projects</a></li>
        <li><a href="teaching.html">Teaching</a></li>
        <!--<li><a href="hobbies.html">Hobbies</a></li>-->
        <li><a href="photography.html">Photography</a></li>
      </ul>
    </div>
    <main id="photography-content">
      <h1>Photography</h1>
      <div class="photo-gallery">
$($galleryItems -join "`r`n")
      </div>
    </main>
    <div class="lightbox" aria-hidden="true" id="lightbox">
      <button aria-label="Close photo" class="lightbox-close" type="button">&times;</button>
      <button aria-label="Previous photo" class="lightbox-previous" type="button">&larr;</button>
      <img alt="Photograph by Brandon Benton" id="lightbox-image">
      <button aria-label="Next photo" class="lightbox-next" type="button">&rarr;</button>
    </div>
    <script>
      const galleryLinks = Array.from(document.querySelectorAll('.photo-gallery a'));
      const lightbox = document.getElementById('lightbox');
      const lightboxImage = document.getElementById('lightbox-image');
      let activePhoto = 0;

      function showPhoto(index) {
        activePhoto = (index + galleryLinks.length) % galleryLinks.length;
        lightboxImage.src = galleryLinks[activePhoto].href;
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

      galleryLinks.forEach((link, index) => {
        link.addEventListener('click', (event) => {
          event.preventDefault();
          openLightbox(index);
        });
      });

      document.querySelector('.lightbox-close').addEventListener('click', closeLightbox);
      document.querySelector('.lightbox-previous').addEventListener('click', () => showPhoto(activePhoto - 1));
      document.querySelector('.lightbox-next').addEventListener('click', () => showPhoto(activePhoto + 1));
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