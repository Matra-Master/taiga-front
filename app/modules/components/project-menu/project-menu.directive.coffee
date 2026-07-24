###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

taiga = @.taiga

SVG_NS = "http://www.w3.org/2000/svg"
# icon-timeline's path (app/svg/sprite.svg), inlined: the compiled menu's own
# sprite (inside its shadow root) doesn't have a changelog/timeline icon, and
# our own sprite isn't reachable from inside that shadow root either.
TIMELINE_ICON_PATH = "M73.967 42.24a11.054 11.054 0 1 0 0 22.104h252.066a11.054" +
    " 11.054 0 1 0 0-22.104zm0 97.824a11.054 11.054 0 1 0 0 22.104h252.066a11.054" +
    " 11.054 0 1 0 0-22.104zm0 97.797a11.054 11.054 0 1 0 0 22.104h252.066a11.054" +
    " 11.054 0 1 0 0-22.104zm0 97.797a11.054 11.054 0 0 0 0 22.104h252.066a11.054" +
    " 11.054 0 0 0 0-22.104z"

ProjectMenuDirective = (projectService, lightboxFactory, $timeout, $translate, $tgLocation) ->
    link = (scope, el, attrs, ctrl) ->
        # tg-project-navigation (the compiled web component loaded via
        # tg-legacy-loader) renders its menu in a real Shadow DOM: our CSS
        # can't reach in, and there's no @Input to add a custom menu item, so
        # "Changelog" is inserted as a real DOM node directly into its own
        # <ul class="menu-secondary"> (where Search/Meetup/Wiki/Team/Settings
        # live, right above the "collapse menu" button). Being real content of
        # that shadow tree, it automatically gets the exact same look, hover
        # state and icon-only collapse behavior as everything around it.
        #
        # That <ul> is destroyed and recreated by Angular on every project
        # change (confirmed empirically: node identity changes on each
        # navigation), so this re-syncs on every ctrl.show() rather than
        # once - see projectChange below.
        syncChangelogMenuItem = () ->
            stickyMenu = el.find('.sticky-project-menu')[0]
            return if not stickyMenu

            loader = stickyMenu.querySelector('tg-legacy-loader')
            return if not loader or not loader.shadowRoot

            ul = loader.shadowRoot.querySelector('ul.menu-secondary')
            return if not ul

            existing = ul.querySelector('.changelog-menu-item')

            if not ctrl.menu.get('changelog')
                existing?.remove()
                return

            return if existing

            # Angular's ViewEncapsulation.Emulated scopes that shadow root's
            # own <style> rules to a per-build attribute (_ngcontent-xxx-cNN).
            # Copying it from a sibling item is what makes our plain node
            # match those rules, whatever the current build's hash is.
            referenceEl = ul.querySelector('li > a, li > button')
            ngAttr = null
            if referenceEl
                ngAttr = _.find(_.map(referenceEl.attributes, (a) -> a.name),
                    (name) -> name.indexOf('_ngcontent') == 0)

            label = $translate.instant('ADMIN.MODULES.CHANGELOG')

            li = document.createElement('li')
            li.className = 'menu-option changelog-menu-item'

            a = document.createElement('a')
            a.href = 'javascript:void(0)'
            a.title = label

            svg = document.createElementNS(SVG_NS, 'svg')
            svg.setAttribute('viewBox', '0 0 400 400')
            path = document.createElementNS(SVG_NS, 'path')
            path.setAttribute('d', TIMELINE_ICON_PATH)
            svg.appendChild(path)

            span = document.createElement('span')
            span.className = 'menu-option-text'
            span.textContent = label

            a.appendChild(svg)
            a.appendChild(span)
            li.appendChild(a)

            if ngAttr
                node.setAttribute(ngAttr, '') for node in [li, a, svg, path, span]

            a.addEventListener 'click', (event) ->
                event.preventDefault()
                slug = projectService.project.get('slug')
                scope.$apply () ->
                    $tgLocation.url("/project/#{slug}/changelog")

            ul.appendChild(li)

        projectChange = () ->
            if projectService.project
                ctrl.show()
                $timeout(syncChangelogMenuItem, 0)
            else
                ctrl.hide()

        scope.$watch ( () ->
            return projectService.project
        ), projectChange

        fixed = false
        topBarHeight = 48

        window.addEventListener "scroll", () ->
            position = $(window).scrollTop()

            if position > topBarHeight && fixed == false
                el.find('.sticky-project-menu').addClass('unblock')
                fixed = true
            else if position == 0 && fixed == true
                el.find('.sticky-project-menu').removeClass('unblock')
                fixed = false

    return {
        scope: {},
        controller: "ProjectMenu",
        controllerAs: "vm",
        templateUrl: "components/project-menu/project-menu.html",
        link: link
    }

ProjectMenuDirective.$inject = [
    "tgProjectService",
    "tgLightboxFactory",
    "$timeout",
    "$translate",
    "$tgLocation"
]

angular.module("taigaComponents").directive("tgProjectMenu", ProjectMenuDirective)
