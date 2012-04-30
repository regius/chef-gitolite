define :post_receive_hook do

  unless params[:username]
    Chef::Log.fatal("git_notifications requres a username to be passed")
  end

  unless params[:type]
    params[:type] = params[:name]
  end

  case params[:type]
  when 'campfire','hipchat'

    if params[:type] == 'campfire'
      gem_package 'tinder'
    elsif params[:type] == 'hipchat'
      gem_package 'hipchat'
    end

    template "/home/#{params[:username]}/.gitolite/hooks/common/#{params[:type]}-hook.rb" do
      source "#{params[:type]}-hook.rb.erb"
      mode 0755
      owner params[:username]
      variables( :config => params[:config] )
    end

    cookbook_file "/home/#{params[:username]}/.gitolite/hooks/common/#{params[:type]}-notification.rb" do
      source "#{params[:type]}-notification.rb"
      mode 0755
      owner params[:username]
    end

    cookbook_file "/home/#{params[:username]}/.gitolite/hooks/common/post-receive" do
      source "#{params[:type]}-post-receive"
      mode 0755
      owner params[:username]
    end
  else
    Chef::Log.fatal("git_notifications requires type 'campfire' or 'hipchat', you passed #{params[:type]}")
  end
end
