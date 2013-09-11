<?php

$ua =  $_SERVER['HTTP_USER_AGENT'];
$allow_offline = true;
if(preg_match('/i(Pod|Phone|Pad)/',$ua) && !preg_match('/Safari/',$ua) && $allow_offline) {
	// It's an iOS webapp
	echo "<html manifest='index.manifest'>";
} else {
	// It's not
	echo "<html>";
}

?>
	<head>
		<script type="text/javascript">
 
		  function logEvent(event) {

		  }
		 
		  window.applicationCache.addEventListener('checking',logEvent,false);
		  window.applicationCache.addEventListener('noupdate',logEvent,false);
		  window.applicationCache.addEventListener('downloading',logEvent,false);
		  window.applicationCache.addEventListener('cached',logEvent,false);
		  window.applicationCache.addEventListener('updateready',logEvent,false);
		  window.applicationCache.addEventListener('obsolete',logEvent,false);
		  window.applicationCache.addEventListener('error',logEvent,false);
		 
		</script>
		<!-- Libraries -->
		<script type='text/javascript' src='js/lib/jquery.js'> </script>
		<script type='text/javascript' src='js/lib/jquery.easing.js'> </script>
		<script type="text/javascript" src='js/lib/mathquill/mathquill.js'></script>
		<script type='text/javascript' src='js/lib/iscroll.js'> </script>
		<script type='text/javascript' src='js/lib/qtransform.js'> </script>
		<script type='text/javascript' src='js/lib/hammer.js'> </script>
		<!-- Models -->
		<script type='text/javascript' src='js/m/Parser.js'> </script>
		<script type='text/javascript' src='js/m/Evaluator.js'> </script>
		<script type='text/javascript' src='js/m/Functions.js'> </script>
		<script type='text/javascript' src='js/m/Solver.js'> </script>
		<!-- Views -->
		<script type='text/elemental' src='js/v/Core.elm'> </script>
		<script type='text/elemental' src='js/v/Keyboard.elm'> </script>
		<script type='text/elemental' src='js/v/MathInput.elm'> </script>
		<script type='text/elemental' src='js/v/LiveEval.elm'> </script>
		<script type='text/elemental' src='js/v/Components.elm'> </script>
		<script type='text/elemental' src='js/v/Grapher.elm'> </script>
		<script type='text/elemental' src='js/v/Functions.elm'> </script>
		<!-- Controllers -->
		<script type='text/javascript' src='js/c/Application.js'> </script>
		<script type='text/javascript' src='js/c/Resource.js'> </script>
		<script type='text/javascript' src='js/c/Storage.js'> </script>
		<script type='text/javascript' src='js/c/Utils.js'> </script>
		<script type='text/javascript' src='js/c/KeyInput.js'> </script>
		<script type='text/javascript' src='js/c/Sound.js'> </script>
		<!-- Elemental -->
		<script type='text/javascript' src='js/lib/elemental.js'> </script>
		<!-- Scripts -->
		<script type='text/javascript' src='js/init.js'> </script>
		<!-- CSS -->
		<link rel='stylesheet' type='text/css' href='css/style.css' />
		<link rel='stylesheet' type='text/css' href='css/lib/touchscroll.css' />
		<link rel="stylesheet" type="text/css" href="js/lib/mathquill/mathquill.css" />

		<!-- Meta -->
		<meta name="viewport" content="initial-scale=1.0, user-scalable=0, minimum-scale=1.0, maximum-scale=1.0" />
		<meta name="apple-mobile-web-app-capable" content="yes" />
		<meta name="apple-mobile-web-app-status-bar-style" content="black" />
		<link rel="apple-touch-icon-precomposed" href="res/icons/sigmabox-512.png"/>
		<!-- Splash -->
			<!-- iPhone 5 -->
			<link href="apple-touch-startup-image-640x1096.png"
			      media="(device-width: 320px) and (device-height: 568px)
			         and (-webkit-device-pixel-ratio: 2)"
			      rel="apple-touch-startup-image">
		<title>Sigmabox</title>
	</head>
	<body>
	
	</body>
</html>
 