<?php
$myvar = "varname";
$x = $_GET['arg'];
eval("$myvar = $x;");

$índice    = $argv[0]; // ¡Cuidado, no hay validación en la entrada de datos!
$consulta  = "SELECT id, name FROM products ORDER BY name LIMIT 20 OFFSET $índice;";
$resultado = pg_query($conexión, $consulta);

?>