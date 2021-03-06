require 'test_helper'

describe WorksController do

  #accessing root does not require login(any guest or logged in user can access)
  describe "root" do
    it "succeeds with all media types" do
      # Precondition: there is at least one media of each category
      get root_path

      must_respond_with :success #its suceesful bc it can fetch the things in the controller?

    end

    it "succeeds with one media type absent" do
      # Precondition: there is at least one media in two of the categories
      work = works(:poodr)
      work.category = "movie"

      get root_path

      must_respond_with :success
    end

    it "succeeds with no media" do
      # original_num_of_works = Work.all.count #this is 4
      Work.destroy_all #this makes it 0

      get root_path

      expect(Work.all.count).must_equal 0

      must_respond_with :success

    end
  end








  describe 'User who is logged in' do
    CATEGORIES = %w(albums books movies)
    INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]

    #perform login before any of these tests
    #having issues with this before so not using it
    before do
      perform_login(users(:dan))
    end



    describe "index" do
      it "succeeds when there are works" do
        perform_login(users(:dan))

        get works_path

        must_respond_with :success
      end

      it "succeeds when there are no works" do

        Work.destroy_all #this makes it

        get root_path

        expect(Work.all.count).must_equal 0
        must_respond_with :success
      end
    end

    describe "new" do
      it "succeeds" do
        #arrange nothing to arrange
        perform_login(users(:dan))

        #act
        get new_work_path
        #assert
        must_respond_with :success
      end
    end

    describe "create" do
      it "creates a work with valid data for a real category" do

        perform_login(users(:dan))

        #arrange
        #must create a new one here because we're testing create so dont just take from yml
        work_hash = {
          work: {
            title: "Great Title",
            creator: "Person",
            description: "The best work on earth",
            publication_year: 2018,
            category: "album"
          }
        }

        #act and assert
        expect {
          post works_path, params: work_hash
        }.must_change 'Work.count', 1

        must_respond_with :redirect

        expect(Work.last.title).must_equal work_hash[:work][:title]
        expect(Work.last.creator).must_equal work_hash[:work][:creator]
        expect(Work.last.description).must_equal work_hash[:work][:description]
        expect(Work.last.publication_year).must_equal work_hash[:work][:publication_year]
        expect(Work.last.category).must_equal work_hash[:work][:category]
      end

      it "renders bad_request and does not update the DB for bogus data" do
        #arrange
        #must create a new one here because we're testing create so dont just take from yml
        work_hash = {
          work: {
            #no title here! which is not valid
            creator: "Person",
            description: "The best work on earth",
            publication_year: 2018,
            category: "album"
          }
        }

        #act and assert
        expect {
          post works_path, params: work_hash
        }.wont_change 'Work.count'

        must_respond_with :bad_request
      end

      it "renders 400 bad_request for bogus categories" do
        #arrange
        #must create a new one here because we're testing create so dont just take from yml
        work_hash = {
          work: {
            #no title here! which is not valid
            creator: "Person",
            description: "The best work on earth",
            publication_year: 2018,
            category: "sculpture"
          }
        }

        #act and assert
        expect {
          post works_path, params: work_hash
        }.wont_change 'Work.count'
        must_respond_with :bad_request
      end

    end

    describe "show" do
      it "succeeds for an extant work ID /aka/ should get a book's show page" do
        perform_login(users(:dan))

        #arrange
        id = works(:poodr).id

        #act
        get work_path(id)

        #assert
        must_respond_with :success

      end

      it "renders 404 not_found for a bogus work ID" do
        perform_login(users(:dan))

        #arrange create invalid id
        id = -1

        #act
        get work_path(id)

        #assert
        must_respond_with :not_found #this goes thru the category_from_work
      end
    end

    describe "edit" do
      it "should get a book's edit page for an extant work ID" do
        perform_login(users(:dan))

        #arrange
        id = works(:poodr).id

        #act
        get edit_work_path(id)

        #assert
        must_respond_with :success

      end

      it "renders 404 not_found for a bogus work ID" do
        id = -1

        get edit_work_path(id)

        must_respond_with :not_found

      end
    end

    describe "update" do
      let (:work_hash) do
        {
          work: {
            title: 'White Teeth',
            creator: works(:album).creator, #just has to have an author that is in yml
            description: 'great movie',
            publication_year: 2000,
            category: 'movie'
          }
        }
      end

      it "succeeds for valid data and an existing work ID" do
        perform_login(users(:dan))

        #arrange
        id = works(:poodr).id

        #act
        expect {
          patch work_path(id), params: work_hash
        }.wont_change 'Work.count'

        #assert
        must_respond_with :redirect
        new_work = Work.find_by(id: id)

        expect(new_work.title).must_equal work_hash[:work][:title]
        expect(new_work.creator).must_equal work_hash[:work][:creator]
        expect(new_work.description).must_equal work_hash[:work][:description]
        expect(new_work.publication_year).must_equal work_hash[:work][:publication_year]
        expect(new_work.category).must_equal work_hash[:work][:category]
      end

      it "renders bad_request for bogus data" do
        # invalidate the work
        work_hash[:work][:title] = nil #user leaves out title when filling in the form
        id = works(:poodr).id
        old_poodr = works(:poodr)

        expect {
          patch work_path(id), params: work_hash
        }.wont_change 'Work.count'
        new_poodr = Work.find(id)

        must_respond_with :bad_request
        expect(old_poodr.title)

      end

      it "renders 404 not_found for a bogus work ID" do

      end
    end

    describe "destroy" do
      it "succeeds for an extant work ID" do
        perform_login(users(:dan))

        #arrange
        media_type = works(:poodr).category
        id = works(:poodr).id
        #concattinate media

        #act
        expect {
          delete work_path(id)
        }.must_change 'Work.count', -1

        #assert
        must_respond_with :redirect
        expect(flash[:result_text]).must_equal "Successfully destroyed #{media_type} #{id}"
        expect(Work.find_by(id: id)).must_equal nil #if its deleted it must equal nil, this is an overkill but just here as example
      end

      it "renders 404 not_found and does not update the DB for a bogus work ID" do
        #arrange
        id = -11

        #act
        expect {
          delete work_path(id)
        }.wont_change 'Work.count'

        #assert
        must_respond_with :not_found
      end
    end

    describe "upvote" do

      it "redirects to the work page if no user is logged in" do

        #in the before action we have dan logged in
        #perform logout
        delete logout_path(:dan)

        #arrange
        id = works(:poodr).id


        #act
        #assert
        expect {
          post upvote_path(id)
        }.wont_change 'Vote.count'

        must_redirect_to root_path
        # post '/works/:id/upvote', to: 'works#upvote', as: 'upvote'
      end

      it "redirects to the work page after the user has logged out" do
        perform_login(users(:dan))

        # 1) already logged in thru before action
        # 2) get a work id
        id = works(:poodr).id

        #act /assert
        # 3) upvote something
        expect {
          post upvote_path(id)
        }.must_change 'Vote.count', 1

        #logout
        logout_path(:dan)

        #must redirect tot he work root page
        must_respond_with :redirect

      end

      it "succeeds for a logged-in user and a fresh user-vote pair" do

        id = works(:poodr).id
        # work = works(:poodr)

        #act /assert
        expect {
          post upvote_path(id)  #dan votes on poodr
        }.must_change 'Vote.count', 1

        must_respond_with :redirect

      end

      it "redirects to the work page if the user has already voted for that work" do
        id = works(:album).id
        work = works(:album)

        #act /assert
        expect {
          post upvote_path(id)  #dan votes on poodr
        }.must_change 'Vote.count', 0

        must_respond_with :redirect

      end
    end #end of upvote


  end #end of users who are logged in








  describe 'Guest users who are not logged in' do
    describe "index" do
      it "redirects when there are works" do
        get works_path

        must_redirect_to :root
      end

      it "redirects when there are no works" do

        Work.destroy_all #this makes it

        get root_path

        expect(Work.all.count).must_equal 0
        must_respond_with :success
      end
     end

    describe "new" do
      it "does not suceed" do
        #arrange nothing to arrange
        #act
        get new_work_path
        #assert
        must_respond_with :redirect
      end
    end

    describe "create" do
      it "CANNOT create a work with valid data for a real category" do

        #arrange
        #must create a new one here because we're testing create so dont just take from yml
        work_hash = {
          work: {
            title: "Great Title",
            creator: "Person",
            description: "The best work on earth",
            publication_year: 2018,
            category: "album"
          }
        }

        #act and assert
        expect {
          post works_path, params: work_hash
        }.must_change 'Work.count', 0

        must_respond_with :redirect
      end

      it "renders redirect and does not update the DB for bogus data" do
        #arrange
        #must create a new one here because we're testing create so dont just take from yml
        work_hash = {
          work: {
            #no title here! which is not valid
            creator: "Person",
            description: "The best work on earth",
            publication_year: 2018,
            category: "album"
          }
        }

        #act and assert
        expect {
          post works_path, params: work_hash
        }.wont_change 'Work.count'

        must_respond_with :redirect
      end

      it "renders redirect for bogus categories" do
        #arrange
        #must create a new one here because we're testing create so dont just take from yml
        work_hash = {
          work: {
            #no title here! which is not valid
            creator: "Person",
            description: "The best work on earth",
            publication_year: 2018,
            category: "sculpture"
          }
        }

        #act and assert
        expect {
          post works_path, params: work_hash
        }.wont_change 'Work.count'

        must_respond_with :redirect
      end

    end

    describe "show" do
      it "redirects for an extant work ID /aka/ cannot get a book's show page" do
        #arrange
        id = works(:poodr).id

        #act
        get work_path(id)

        #assert
        must_respond_with :redirect

      end

      it "renders redirect for a bogus work ID" do
        #arrange create invalid id
        id = -1

        #act
        get work_path(id)

        #assert
        must_respond_with :redirect #this goes thru the category_from_work
      end
    end

    describe "edit" do
      it "CANNOT get a book's edit page for an extant work ID" do
        #arrange
        id = works(:poodr).id

        #act
        get edit_work_path(id)

        #assert
        must_respond_with :redirect

      end

      it "renders redirect for a bogus work ID" do
        id = -1

        get edit_work_path(id)

        must_respond_with :redirect

      end
    end
    #
    describe "update" do
      let (:work_hash) do
        {
          work: {
            title: 'White Teeth',
            creator: works(:album).creator, #just has to have an author that is in yml
            description: 'great movie',
            publication_year: 2000,
            category: 'movie'
          }
        }
      end

      it "redirects when given valid data and an existing work ID" do
        #arrange
        id = works(:poodr).id

        #act
        expect {
          patch work_path(id), params: work_hash
        }.wont_change 'Work.count'

        #assert
        must_respond_with :redirect
      end

      it "renders redirect for bogus data" do
        # invalidate the work
        work_hash[:work][:title] = nil #user leaves out title when filling in the form
        id = works(:poodr).id
        old_poodr = works(:poodr)

        expect {
          patch work_path(id), params: work_hash
        }.wont_change 'Work.count'

        must_respond_with :redirect

      end

    end

    describe "destroy" do
      it "DOESNT succeed for an extant work ID" do
        #arrange
        media_type = works(:poodr).category
        id = works(:poodr).id
        #concattinate media

        #act
        expect {
          delete work_path(id)
        }.must_change 'Work.count', 0

        #assert
        must_respond_with :redirect
      end

      it "renders redirect and does not update the DB for a bogus work ID" do
        #arrange
        id = -11

        #act
        expect {
          delete work_path(id)
        }.wont_change 'Work.count'

        #assert
        must_respond_with :redirect
      end
    end

    describe "upvote" do

      it "redirects to the work page if no user is logged in" do

        #arrange
        id = works(:poodr).id


        #act
        #assert
        expect {
          post upvote_path(id)
        }.wont_change 'Vote.count'

        must_respond_with :redirect
        # post '/works/:id/upvote', to: 'works#upvote', as: 'upvote'
      end


      it "doesn't succeed for guest user and a fresh user-vote pair" do

        id = works(:poodr).id
        # work = works(:poodr)

        #act /assert
        expect {
          post upvote_path(id)  #dan votes on poodr
        }.must_change 'Vote.count', 0

        must_respond_with :redirect

      end

      it "redirects to the work page if the user has already voted for that work" do
        id = works(:album).id
        work = works(:album)

        #act /assert
        expect {
          post upvote_path(id)  #dan votes on poodr
        }.must_change 'Vote.count', 0

        must_respond_with :redirect

      end
    end #end of upvote
  end #end of guest users








end #end of works controller test
