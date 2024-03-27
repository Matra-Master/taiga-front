###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos INC
###

taiga = @.taiga

mixOf = @.taiga.mixOf
debounceLeading = @.taiga.debounceLeading

class NotificationsController extends mixOf(taiga.Controller, taiga.PageMixin, taiga.FiltersMixin)
    @.$inject = [
        "$rootScope",
        "$scope",
        "tgNotificationsService"
        "tgCurrentUserService",
        "$tgEvents",
        "$location"
        "$window"
    ]

    constructor: (@rootScope, @scope, @notificationsService, @currentUserService, @events,
    @location, @window) ->
        @.total = 0
        @.user = @currentUserService.getUser()
        @.scrollDisabled = false
        @.initList()
        @.loadNotifications()

        @rootScope.$on "notifications:dismiss", (event) =>
            if @.onlyUnread
                @.reloadList()

        @rootScope.$on "notifications:new", (event) =>
            @.reloadList()

        @rootScope.$on "notifications:dismiss-all", (event) =>
            @.reloadList()

    initList: ()->
        @.notificationsList = Immutable.List()
        if @.user
            @.list = @notificationsService.getNotificationsList(@.user.get("id"), @.onlyUnread?)

        @.loading = !@.list?

    reloadList: ()->
        @.initList()
        @.loadNotifications()

    loadNotifications: () ->
        @.scrollDisabled = true
        @.loading = true
        @scope.$emit("notifications:loading")
        return @.list
            .next()
            .then (response) =>
                @.notificationsList = @.notificationsList.concat(response.get("items"))

                if !@.infiniteScrollDisabled && response.get("next")
                    @.scrollDisabled = false

                @.total = response.get("total")

                @scope.$emit("notifications:loaded", @.total)

                @.loading = false
                return @.notificationsList

    setAsRead: (notification, url) ->
        @notificationsService.setNotificationAsRead(notification.get("id")).then =>
            if @location.$$url == url
                @window.location.reload()
            else
                @location.path(url)

            @rootScope.$broadcast "notifications:dismiss"

    setAllAsRead: () ->
        @notificationsService.setNotificationsAsRead().then =>
            @rootScope.$broadcast "notifications:dismiss-all"


angular.module("taigaNotifications").controller("Notifications", NotificationsController)
