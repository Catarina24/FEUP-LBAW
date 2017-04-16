<?php
funtion displayEvents(){
  $stmt = $conn->prepare('SELECT * FROM public.Event');
  $stmt->execute();
  $events = $stmt->fetchAll();

  foreach ($events as $event) {
?>

<div class="container-fluid event-card-medium">
    <p class="titulo-card"><?=$event['name']?></p>
    <div class="row">
        <div class="col-sm-3">
            <img src=<?=$event['phot_url']?>/>
        </div>
        <div class="col-sm-9">
            <p class="text-card"><?=$event['description']?></p>
            <p class="text-card"><?=$event['beginning_date']?> - <?=$event['ending_date']?></p>
            <p class="text-card"><?=$event['local-id']?><p> <!--procurar nome do local-->
            <p class="text-card">Gratuito</p> <!--verificar se é gratis ou nao e se nao for por preço-->
            <div class="container-fluid">
                <div class="row">
                    <button type="button" class="btn btn-default col-sm-5">See More...</button>
                    <div class="classifica-card col-sm-7">
                        <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                        <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                        <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                        <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                        <i class="fa fa-star-o fa-2x" aria-hidden="true"></i>
                    </div>
                </div>

            </div>
        </div>
    </div>
</div>
<?php
  }
} ?>
