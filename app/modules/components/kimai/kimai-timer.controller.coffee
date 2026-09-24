class KimaiTimerController
    constructor: () ->
        @.loading = false
        @.activities = null

angular.module("taigaComponents").controller("KimaiTimerController", KimaiTimerController)
