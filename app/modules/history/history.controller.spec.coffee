###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe "HistorySection", ->
    provide = null
    controller = null
    mocks = {}

    _mockTgResources = () ->
        mocks.tgResources = {
            history: {
                get: sinon.stub()
                deleteComment: sinon.stub()
                undeleteComment: sinon.stub()
                editComment: sinon.stub()
            }
        }

        provide.value "$tgResources", mocks.tgResources

    _mockTgRepo = () ->
        mocks.tgRepo = {
            save: sinon.stub()
        }

        provide.value "$tgRepo", mocks.tgRepo

    _mocktgStorage = () ->
        mocks.tgStorage = {
            get: sinon.stub()
            set: sinon.stub()
        }
        provide.value "$tgStorage", mocks.tgStorage

    _mockTgProjectService = () ->
        mocks.tgProjectService = {
            hasPermission: sinon.stub()
        }
        provide.value "tgProjectService", mocks.tgProjectService

    _mockTgActivityService = () ->
        mocks.tgActivityService = {
            init: sinon.stub()
            fetchEntries: sinon.stub()
            count: null
        }
        provide.value "tgActivityService", mocks.tgActivityService

    _mockTgWysiwygService = () ->
        mocks.tgWysiwygService = {
            refreshAttachmentURL: sinon.stub()
        }
        provide.value "tgWysiwygService", mocks.tgWysiwygService

    _mocks = () ->
        module ($provide) ->
            provide = $provide
            _mockTgResources()
            _mockTgRepo()
            _mocktgStorage()
            _mockTgProjectService()
            _mockTgActivityService()
            _mockTgWysiwygService()
            return null

    beforeEach ->
        module "taigaHistory"

        _mocks()

        inject ($controller) ->
            controller = $controller
        mocks.tgResources.history.get.promise().resolve()
        mocks.tgActivityService.fetchEntries.promise().resolve()

    it "load historic", () ->
        historyCtrl = controller "HistorySection"

        historyCtrl._loadComments = sinon.stub()
        historyCtrl._loadActivity = sinon.stub()

        historyCtrl._loadHistory()
        expect(historyCtrl._loadComments).have.been.called
        expect(historyCtrl._loadActivity).have.been.called

    it "get Comments older first", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl.name = 'foo'
        historyCtrl.id = 3
        historyCtrl.reverse = false

        comments = ['comment3', 'comment2', 'comment1']
        mocks.tgResources.history.get.withArgs('foo', 3, 'comment').promise().resolve(comments)

        historyCtrl._loadComments().then () ->
            expect(historyCtrl.comments).to.be.eql(['comment3', 'comment2', 'comment1'])
            expect(historyCtrl.commentsNum).to.be.equal(3)

    it "get Comments newer first", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl.name = 'foo'
        historyCtrl.id = 3
        historyCtrl.reverse = true

        comments = ['comment3', 'comment2', 'comment1']
        mocks.tgResources.history.get.withArgs('foo', 3, 'comment').promise().resolve(comments)

        historyCtrl._loadComments().then () ->
            expect(historyCtrl.comments).to.be.eql(['comment1', 'comment2', 'comment3'])
            expect(historyCtrl.commentsNum).to.be.equal(3)

    it "get activities", () ->
        historyCtrl = controller "HistorySection"

        activities = Immutable.List([
            {id: 1, name: 'history entry 1'},
            {id: 2, name: 'history entry 2'},
            {id: 3, name: 'history entry 3'},
        ])
        mocks.tgActivityService.fetchEntries.withArgs().promise().resolve(activities)

        historyCtrl._loadActivity().then () ->
            expect(historyCtrl.activities.length).to.be.equal(3)

    it "on active history tab", () ->
        historyCtrl = controller "HistorySection"
        active = true
        historyCtrl.onActiveHistoryTab(active)
        expect(historyCtrl.viewComments).to.be.true

    it "on inactive history tab", () ->
        historyCtrl = controller "HistorySection"
        active = false
        historyCtrl.onActiveHistoryTab(active)
        expect(historyCtrl.viewComments).to.be.false

    it "delete comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadComments = sinon.stub()

        historyCtrl.name = "type"
        historyCtrl.id = 1

        type = historyCtrl.name
        objectId = historyCtrl.id
        commentId = 7

        deleteCommentPromise = mocks.tgResources.history.deleteComment
        .withArgs(type, objectId, commentId).promise()

        ctrlPromise = historyCtrl.deleteComment(commentId)
        expect(historyCtrl.deleting).to.be.equal(7)

        deleteCommentPromise.resolve()

        ctrlPromise.then () ->
            expect(historyCtrl._loadComments).have.been.called
            expect(historyCtrl.deleting).to.be.null

    it "edit comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadComments = sinon.stub()

        historyCtrl.name = "type"
        historyCtrl.id = 1
        activityId = 7
        comment = "blablabla"

        type = historyCtrl.name
        objectId = historyCtrl.id
        commentId = activityId

        promise = mocks.tgResources.history.editComment
        .withArgs(type, objectId, activityId, comment).promise().resolve()

        historyCtrl.editing = 7
        historyCtrl.editComment(commentId, comment).then () ->
            expect(historyCtrl._loadComments).has.been.called
            expect(historyCtrl.editing).to.be.null

    it "restore comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadComments = sinon.stub()

        historyCtrl.name = "type"
        historyCtrl.id = 1
        activityId = 7

        type = historyCtrl.name
        objectId = historyCtrl.id
        commentId = activityId

        promise = mocks.tgResources.history.undeleteComment.withArgs(type, objectId, activityId).promise().resolve()

        historyCtrl.editing = 7
        historyCtrl.restoreDeletedComment(commentId).then () ->
            expect(historyCtrl._loadComments).has.been.called
            expect(historyCtrl.editing).to.be.null

    it "add comment", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadComments = sinon.stub()

        historyCtrl.type = "type"
        type = historyCtrl.type

        cb = sinon.spy()

        promise = mocks.tgRepo.save.withArgs(type).promise().resolve()

        historyCtrl.addComment()
        expect(historyCtrl._loadComments).has.been.called


    it "order comments", () ->
        historyCtrl = controller "HistorySection"
        historyCtrl._loadComments = sinon.stub()

        historyCtrl.reverse = false

        historyCtrl.onOrderComments()
        expect(historyCtrl.reverse).to.be.true
        expect(mocks.tgStorage.set).has.been.calledWith("orderComments", historyCtrl.reverse)
        expect(historyCtrl._loadComments).has.been.called
