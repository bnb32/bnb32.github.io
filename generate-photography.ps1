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
    </style>
  </head>
  <body>
    <div id="wrapper">
      <ul id="navbar">
        <li><a href="index.html#about">About Me</a></li>
        <li><a href="index.html#research">Research</a></li>
        <li><a href="index.html#sides">Side Projects</a></li>
        <li><a href="index.html#teaching">Teaching</a></li>
        <li><a href="photography.html">Photography</a></li>
      </ul>
    </div>
    <main id="photography-content">
      <h1>Photography</h1>
      <div class="photo-gallery">
$($galleryItems -join "`r`n")
      </div>
    </main>
  </body>
</html>
"@

Set-Content -Path $outputFile -Value $document -Encoding ascii