###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe "LbContactProject", ->
    provide = null
    controller = null
    mocks = {}

    _mockTgLightboxSercice = () ->
        mocks.tglightboxService = {
            closeAll: sinon.stub()
        }

        provide.value "lightboxService", mocks.tglightboxService

    _mockTgResources = () ->
        mocks.tgResources = {
            projects: {
                contactProject: sinon.stub()
            }
        }

        provide.value "tgResources", mocks.tgResources

    _mockTgConfirm = () ->
        mocks.tgConfirm = {
            notify: sinon.stub()
        }

        provide.value "$tgConfirm", mocks.tgConfirm

    _mocks = () ->
        module ($provide) ->
            provide = $provide
            _mockTgLightboxSercice()
            _mockTgResources()
            _mockTgConfirm()

            return null

    beforeEach ->
        module "taigaProjects"

        _mocks()

        inject ($controller) ->
            controller = $controller

    it "Contact Project", (done) ->
        ctrl = controller("ContactProjectLbCtrl")
        ctrl.contact = {
            message: 'abcde'
        }
        ctrl.project = Immutable.fromJS({
            id: 1
        })

        project = ctrl.project.get('id')
        message = ctrl.contact.message

        promise = mocks.tgResources.projects.contactProject.withArgs(project, message).promise().resolve()

        ctrl.sendingFeedback = true

        ctrl.contactProject().then () ->
            expect(mocks.tglightboxService.closeAll).have.been.called
            expect(ctrl.sendingFeedback).to.be.false
            expect(mocks.tgConfirm.notify).have.been.calledWith("success")
            done()
