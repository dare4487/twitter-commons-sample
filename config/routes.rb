Rails.application.routes.draw do
  # resources :abstract_resources

  # prefer and defer elements (setting preferred true|false)
  concern :preferring do
    member do
      get 'prefer'
      get 'defer'
    end
  end

  # attach and detach the route in question to its 'parent'
  concern :attaching do
    member do
      get 'attach'
      get 'detach'
    end
  end

  # activate and passify the route in question
  concern :activating do
    member do
      get 'activate'
      get 'deactivate'
    end
  end

end
