{include file='common/header.tpl'}

{if $USERNAME}
    {include file='common/aside-menu.tpl'}
{/if}

<div class="container-fluid text-left">
    <div class="row">
        <content class="col-lg-offset-3 col-lg-6 col-sm-8 col-sm-offset-1 col-xs-12 page">
            <div class="page-header">
                <h1>Events that I created</h1>
            </div>

            {if $events==NULL}
                <h3>You haven't created any events yet.</h3>
            {else}

                {foreach $events as $event}
                    <div class="event-card-medium row">
                        <div class="col-sm-12">
                            <p class="titulo-card">{$event.name}</p>
                        </div>

                        <div class="col-sm-3">
                            <img src="../../resources/images/2.jpg"/>
                        </div>
                        <div class="col-sm-9">
                            <p class="text-card"> {$event.date}</p>
                            <p class="text-card"> {$event.location}</p>
                            <p></p>
                            {if $event.free}
                                <p class="text-card">Free</p>
                            {else}
                                <p class="text-card">Paid</p>
                            {/if}
                            <div class="row">
                                <div class="classifica-card col-sm-7">
                                    <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                                    <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                                    <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                                    <i class="fa fa-star fa-2x" aria-hidden="true"></i>
                                    <i class="fa fa-star-o fa-2x" aria-hidden="true"></i>
                                </div>
                            </div>

                            <div class="row">
                                <p></p>
                                <button onclick="window.location.href='{$BASE_URL}pages/event/show-event-page.php?id={$event.event_id}'"
                                        type="button" class="btn btn-default col-sm-5">See Event
                                </button>
                                <button onclick="window.location.href='../../pages/event/edit-event.php'"
                                        type="button" class="btn btn-default col-sm-5">Edit Event
                                </button>
                            </div>
                        </div>
                    </div>
                {/foreach}
            {/if}
        </content>
    </div>
</div>

{include file='common/footer.tpl'}