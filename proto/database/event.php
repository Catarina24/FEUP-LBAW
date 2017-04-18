<?php
  function getAllEvents($page) {
    global $conn;
    $stmt = $conn->prepare('SELECT * FROM public.Event LIMIT 10 OFFSET ? * 10;');
    $stmt->execute(array($page));
    return $stmt->fetchAll();
  }
  
  /**
  $page, numero da pagina
  $name, nome do evento a procurar
  $free, true se procurar em free
  $paid, true se procurar em paid
  $nameOrPrice, true se nome false se price
  $asc, ASC ou DESC
  */
   function getSearchEvents($page, $name, $free, $paid, $nameOrPrice, $asc) {
    global $conn;
	$param = "%$name%";
	$stringfreee = "";
	$stringpaid = "";
	if($free == false){
		$stringfreee = " AND free = false";
	}
	
	if($paid == false){
		$stringpaid = " AND free = true";
	}
	echo $stringfreee;
	echo $stringpaid;
	if($nameOrPrice){ //name
		$stringnNOP = "name"; //"name, price" falta implementar o price
	}else{
		$stringnNOP = "name"; //"price, name" falta implementar o price
    }
	echo 'SELECT *
							FROM public.Event  INNER JOIN public.Localization ON (public.Event.local_id = public.Localization.local_id)
							WHERE upper(name) LIKE upper(?)' . $stringfreee . $stringpaid .
							' ORDER BY ' . $stringnNOP . ' ' . $asc . 
							' LIMIT 10 OFFSET ? * 10;';
	$stmt = $conn->prepare('SELECT *
							FROM public.Event  INNER JOIN public.Localization ON (public.Event.local_id = public.Localization.local_id)
							WHERE upper(name) LIKE upper(?)' . $stringfreee . $stringpaid .
							' ORDER BY ' . $stringnNOP . ' ' . $asc . 
							' LIMIT 10 OFFSET ? * 10;');
    $stmt->execute(array($param, $page));
    return $stmt->fetchAll();
  }
?>