﻿{include file='common/header.tpl'}

{if $USERNAME}
    {include file='common/aside-menu.tpl'}
{/if}

<div class="container-fluid text-left">
    <div class="row">
        <content class="col-lg-offset-3 col-lg-6 col-sm-8 col-sm-offset-1 col-xs-12 page">
            <div class="page-header">
                <h1>Create new event</h1>
            </div>

            <form action="../../actions/event/new_event.php" id="msform" method="post" enctype="multipart/>form-data"
                  onSubmit="showValues(this)">

                <!--<fieldset id="page1">
                    <span class="error" id="error"></span>
                    <div class="row">
                        <content class="col-md-8 col-xs-8">
                            <label class="special-label">Event Name *</label>
                            <input type="text" name="event-name" class="form-control event_name" placeholder="Event Name"
                                   aria-describedby="basic-addon1" required>
                        </content>
                        <content class="col-md-offset-1 col-md-1 col-xs-2">
                            <label>Public</label>
                            <input type="checkbox" class="checkbox-form" name="public">
                        </content>
                        <content class="col-md-offset-1 col-md-1 col-xs-2">
                            <label>Free</label>
                            <input type="checkbox" class="checkbox-form" name="free">
                        </content>
                    </div>

                    <div class="row">
                        <content class="col-xs-6">
                            <label>Date *</label>
                            <input type="date" name="beginning-event-date" class="form-control beginning_date"
                                   placeholder="Date"
                                   aria-describedby="basic-addon1" required>

                        </content>
                        <content class="col-xs-6">
                            <label>Time *</label>
                            <input type="time" name="beginning-event-time" class="form-control beginning_time" placeholder="Time"
                                   aria-describedby="basic-addon1" required>
                        </content>
                    </div>

                    <div class="row">
                        <content class="col-xs-6">
                            <label>Ending Date</label>
                            <input type="date" name="ending-event-date" class="form-control ending_date"
                                   placeholder="Date"
                                   aria-describedby="basic-addon1">

                        </content>
                        <content class="col-xs-6">
                            <label>Ending Time</label>
                            <input type="time" name="ending-event-time" class="form-control ending_time" placeholder="Time"
                                   aria-describedby="basic-addon1">
                        </content>
                    </div>

                    <div class="row">

                        <content class="col-xs-6">
                            <label>Category</label>
                            <select class="form-control" name="category">
                                <option value="1">---</option>
                                <option value="2">Arts</option>
                                <option value="3">Business</option>
                                <option value="4">Charity</option>
                                <option value="5">Food & Drink</option>
                                <option value="6">Music</option>
                            </select>
                        </content>
                    </div>

                    <label>Description *</label>
                    <textarea rows="4" cols="50" name="description" placeholder="Describe the event here"
                              class="form-control description"
                              required></textarea>

                    <div>
                        <label for="event-photo" class="btn btn-default">Upload photo</label>
                        <input id="event-photo" style="visibility:hidden;" name="event-photo" type="file">
                    </div>

                    <p></p>
                    <input type="reset" class="btn btn-default" value="Reset"/>
                    <input type="button" name="next" class="next btn btn-default" value="Next"/>
                    <p></p>

                </fieldset>

                <fieldset id="page2">

                    <span class="error" id="error2"></span>
                    <p></p>
                    <label>Local *</label>
                    <input id="local-searchbox" name="local-searchbox" class="form-control" type="text"
                           placeholder="Search Location" aria-describedby="basic-addon1">

                    <div id="map" style="width: 100%; height: 300px;"></div>

                    <input type="text" name="lat" id="lat" hidden="true" required>
                    <input type="text" name="lng" id="lng" hidden="true" required>
                    <input type="text" name="city" id="city" hidden="true" required>
                    <input type="text" name="country" id="country" hidden="true" required>
                    <input type="text" name="street" id="street" hidden="true" required>

                    <p></p>
                    <input type="button" name="previous" class="previous btn btn-default" value="Previous"/>
                    <input type="button" name="next" class="next btn btn-default" value="Next"/>
                    <p></p>
                </fieldset>-->

                <fieldset id="page3">
                    <div class="row">
                        <content class="col-sm-12">
                            <label>Add Hosts</label>
                            <div class="inner">

                                <select style="width: 100%;" class="js-example-basic-multiple" multiple="multiple">
                                    <option value="AL">Alabama</option>
                                    <option value="WY">Wyoming</option>
                                </select>

                                <select style="width: 100%;" class="js-data-example-ajax">
                                    <option value="3620194" selected="selected">select2/select2</option>
                                </select>
                            </div>

                            <!--<div class="inner">
                                <input id="search-user" name="username" type="search" class="form-control"
                                       Placeholder="Search..." autocomplete="off"/>
                                <span data-icon="&#xe000;" aria-hidden="true" class="search-btn">
                                        <input type="submit" class="searchsubmit" value="">
                                    </span>
                            </div>
                            <div class="content-list" id="host-list">
                                <ul class="drop-list" id="drop-list">

                                </ul>
                            </div>-->
                        </content>
                        <content class="col-sm-12" id="added-hosts">

                        </content>

                        <content class="col-sm-12">
                            <label>Invite People</label>
                        </content>

                        <!--<div class="inner">
                            <input id="search-user" name="username" type="search" class="form-control"
                                   Placeholder="Search..." autocomplete="false"/>
                            <span data-icon="&#xe000;" aria-hidden="true" class="search-btn">
                                    <input type="submit" class="searchsubmit" value="">
                                </span>
                        </div>
                        <div class="content-list" id="host-list">
                            <ul class="drop-list">
                                <li>
                                    <a href="">
                            <span class="item">
                                <span class="icon people">
                                    <span data-icon="&#xe001;" aria-hidden="true"></span>
                                </span>
                                <span class="text">People I may know</span>
                            </span>
                                    </a>
                                </li>
                            </ul>
                        </div>-->

                        <br></br>
                        <input type="button" name="previous" class="previous btn btn-default" value="Previous"/>
                        <button type="submit" class="btn btn-default">Create event!</button>
                        <br></br>
                    </div>
                </fieldset>
            </form>
        </content>
    </div>
</div>

<script type="text/javascript">
    BASE_URL = "/";
    $(".js-example-basic-multiple").select2({
        ajax: {
            url: BASE_URL+"api/search/searchUsers.php",
            dataType: 'json',
            delay: 250,
            data: function (params) {
                console.log(params);
                return {
                    q: params.term, // search term
                    page: params.page
                };
            },
            processResults: function (data, params) {
                console.log(data.users);
                params.page = params.page || 1;

                return {
                    results: data.users,
                    pagination: {
                        more: (params.page * 30) < data.users.length
                    }
                };
            },
            cache: true
        },
        escapeMarkup: function (markup) { return markup; },
        minimumInputLength: 1,
        templateResult: formatUser,
        templateSelection: formatUserSelection
    });
/*
    $(".js-example-basic-multiple").select2({
        ajax: {
            url: "https://api.github.com/search/repositories",
            dataType: 'json',
            delay: 250,
            data: function (params) {
                return {
                    q: params.term, // search term
                    page: params.page
                };
            },
            processResults: function (data, params) {
                console.log(data);
                params.page = params.page || 1;

                return {
                    results: data.items,
                    pagination: {
                        more: (params.page * 30) < data.total_count
                    }
                };
            },
            cache: true
        },
        escapeMarkup: function (markup) { return markup; }, // let our custom formatter work
        minimumInputLength: 1,
        templateResult: formatRepo, // omitted for brevity, see the source of this page
        templateSelection: formatRepoSelection
    });*/

    function formatUser (user) {
        if (user.loading) return user.text;

        var markup = "<div class='select2-result-repository clearfix'>" +
            "<div class='select2-result-repository__meta'>" +
            "<div class='select2-result-repository__title'>" + user.username + "</div>";

        return markup;
    }

    function formatRepo (repo) {
        if (repo.loading) return repo.text;

        var markup = "<div class='select2-result-repository clearfix'>" +
            "<div class='select2-result-repository__avatar'></div>" +
            "<div class='select2-result-repository__meta'>" +
            "<div class='select2-result-repository__title'>" + repo.full_name + "</div>";

       /* if (repo.description) {
            markup += "<div class='select2-result-repository__description'>" + repo.description + "</div>";
        }

        markup += "<div class='select2-result-repository__statistics'>" +
            "<div class='select2-result-repository__forks'><i class='fa fa-flash'></i> " + repo.forks_count + " Forks</div>" +
            "<div class='select2-result-repository__stargazers'><i class='fa fa-star'></i> " + repo.stargazers_count + " Stars</div>" +
            "<div class='select2-result-repository__watchers'><i class='fa fa-eye'></i> " + repo.watchers_count + " Watchers</div>" +
            "</div>" +
            "</div></div>";*/

        return markup;
    }

    function formatRepoSelection (repo) {
        return repo.full_name || repo.text;
    }

    function formatUserSelection (user) {
        console.log(user);
        return user.username;
    }

</script>

{include file='common/footer.tpl'}

<script type="text/javascript" src="../../scripts/map.js"></script>
<script type="text/javascript" src="../../scripts/event/change-page-form.js"></script>
<script class="cssdeck" src="//cdnjs.cloudflare.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
<script src="{$BASE_URL}scripts/search/create-event-search.js"></script>