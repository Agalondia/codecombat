CreateAccountModal = require 'views/core/CreateAccountModal'
forms = require 'core/forms'

describe 'CreateAccountModal', ->
  
  modal = null
  
  beforeEach ->
    modal = new CreateAccountModal()
    modal.render()
    window.gapi =
      client:
        load: _.noop
    window.FB =
      login: _.noop
      api: _.noop
        
  afterEach ->
    modal.stopListening()

  describe 'clicking the save button', ->
    
    it '(demo)', ->
      jasmine.demoModal(modal)
      modal.$('form').each (i, el) -> el.reset()
      forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy' })
      modal.$('form:first').submit()
    
    it 'fails if nothing is in the form', ->
      modal.$('form').each (i, el) -> el.reset()
      modal.$('form:first').submit()
      expect(jasmine.Ajax.requests.all().length).toBe(0)
      expect(modal.$el.has('.has-warning').length).toBeTruthy()
    
    it 'fails if email is missing', ->
      modal.$('form').each (i, el) -> el.reset()
      forms.objectToForm(modal.$el, { name: 'Name', password: 'xyzzy' })
      modal.$('form:first').submit()
      expect(jasmine.Ajax.requests.all().length).toBe(0)
      expect(modal.$el.has('.has-warning').length).toBeTruthy()

    it 'signs up if only email and password is provided', ->
      jasmine.demoModal(modal)
      modal.$('form').each (i, el) -> el.reset()
      forms.objectToForm(modal.$el, { email: 'some@email.com', password: 'xyzzy' })
      modal.$('form:first').submit()
      requests = jasmine.Ajax.requests.all()
      expect(requests.length).toBe(1)
      expect(modal.$el.has('.has-warning').length).toBeFalsy()
      expect(modal.$('#signup-button').is(':disabled')).toBe(true)
      
  describe 'clicking the gplus button', ->
    
    signupButton = null
    
    beforeEach ->
      application.gplusHandler.trigger 'render-login-buttons'
      signupButton = modal.$('#gplus-signup-btn')
      expect(signupButton.attr('disabled')).toBeFalsy()
      signupButton.click()
      application.gplusHandler.fakeGPlusLogin()
      application.gplusHandler.trigger 'person-loaded', { firstName: 'Mr', lastName: 'Bean', gplusID: 'abcd', email: 'some@email.com' }
    
    it '(demo)', ->
      modal.render = _.noop
      jasmine.demoModal(modal)
    
    it 'checks to see if the user already exists in our system', ->
      requests = jasmine.Ajax.requests.all()
      expect(requests.length).toBe(1)
      expect(signupButton.attr('disabled')).toBeTruthy()


    describe 'and finding the given person is already a user', ->
      beforeEach ->
        expect(modal.$('#gplus-account-exists-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 200, responseText: JSON.stringify({_id: 'existinguser'})})

      it '(demo)', ->
        modal.render = _.noop
        jasmine.demoModal(modal)

      it 'shows a message saying you are connected with Google+, with a button for logging in', ->
        expect(modal.$('#gplus-account-exists-row').hasClass('hide')).toBe(false)
        loginBtn = modal.$('#gplus-login-btn')
        expect(loginBtn.attr('disabled')).toBeFalsy()
        loginBtn.click()
        expect(loginBtn.attr('disabled')).toBeTruthy()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.method).toBe('POST')
        expect(request.params).toBe('gplusID=abcd&gplusAccessToken=1234')
        expect(request.url).toBe('/auth/login-gplus')

    describe 'and finding the given person is not yet a user', ->
      beforeEach ->
        expect(modal.$('#gplus-logged-in-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 404})
        
      it '(demo)', ->
        modal.render = _.noop
        jasmine.demoModal(modal)
        
      it 'shows a message saying you are connected with Google+', ->
        expect(modal.$('#gplus-logged-in-row').hasClass('hide')).toBe(false)
        
      describe 'and the user finishes signup', ->
        beforeEach ->
          modal.$('form:first').submit()

        it '(demo)', ->
          modal.render = _.noop
          jasmine.demoModal(modal)
          
        it 'creates the user with the gplus attributes', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
          expect(modal.$('#signup-button').is(':disabled')).toBe(true)
          
        
  describe 'clicking the facebook button', ->

    signupButton = null

    beforeEach ->
      Backbone.Mediator.publish 'auth:facebook-api-loaded', {}
      signupButton = modal.$('#facebook-signup-btn')
      expect(signupButton.attr('disabled')).toBeFalsy()
      signupButton.click()
      application.facebookHandler.fakeFacebookLogin()
      application.facebookHandler.trigger 'person-loaded', { firstName: 'Mr', lastName: 'Bean', facebookID: 'abcd', email: 'some@email.com' }

    it '(demo)', ->
      modal.render = _.noop
      jasmine.demoModal(modal)

    it 'checks to see if the user already exists in our system', ->
      requests = jasmine.Ajax.requests.all()
      expect(requests.length).toBe(1)
      expect(signupButton.attr('disabled')).toBeTruthy()


    describe 'and finding the given person is already a user', ->
      beforeEach ->
        expect(modal.$('#facebook-account-exists-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 200, responseText: JSON.stringify({_id: 'existinguser'})})

      it '(demo)', ->
        modal.render = _.noop
        jasmine.demoModal(modal)

      it 'shows a message saying you are connected with Facebook, with a button for logging in', ->
        expect(modal.$('#facebook-account-exists-row').hasClass('hide')).toBe(false)
        loginBtn = modal.$('#facebook-login-btn')
        expect(loginBtn.attr('disabled')).toBeFalsy()
        loginBtn.click()
        expect(loginBtn.attr('disabled')).toBeTruthy()
        request = jasmine.Ajax.requests.mostRecent()
        expect(request.method).toBe('POST')
        expect(request.params).toBe('facebookID=abcd&facebookAccessToken=1234')
        expect(request.url).toBe('/auth/login-facebook')


    describe 'and finding the given person is not yet a user', ->
      beforeEach ->
        expect(modal.$('#facebook-logged-in-row').hasClass('hide')).toBe(true)
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 404})

      it '(demo)', ->
        modal.render = _.noop
        jasmine.demoModal(modal)

      it 'shows a message saying you are connected with Facebook', ->
        expect(modal.$('#facebook-logged-in-row').hasClass('hide')).toBe(false)

      describe 'and the user finishes signup', ->
        beforeEach ->
          modal.$('form:first').submit()

        it '(demo)', ->
          modal.render = _.noop
          jasmine.demoModal(modal)

        it 'creates the user with the facebook attributes', ->
          request = jasmine.Ajax.requests.mostRecent()
          expect(request.method).toBe('PUT')
          expect(_.string.startsWith(request.url, '/db/user')).toBe(true)
          expect(modal.$('#signup-button').is(':disabled')).toBe(true)