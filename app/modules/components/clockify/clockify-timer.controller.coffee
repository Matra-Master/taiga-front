class ClockifyTimerController
    @.$inject = [
        "tgCurrentUserService",
        "$scope"
    ]

    constructor: (@currentUserService, @scope) ->
        @.user = @currentUserService.getUser()
        @.loading = false

angular.module("taigaComponents").controller("ClockifyTimerController", ClockifyTimerController)
