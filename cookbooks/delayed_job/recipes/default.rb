#
# Cookbook Name:: delayed_job
# Recipe:: default
#

if ['solo', 'util'].include?(node[:instance_role])

  # be sure to replace "app_name" with the name of your application.
  run_for_app("fotog") do |app_name, data|
  
    # determine the number of workers to run based on instance size
    if node[:instance_role] == 'solo'
      worker_count = 1
    else
      case node[:ec2][:instance_type]
      when 'm1.small': worker_count = 2
      when 'c1.medium': worker_count = 4
      when 'c1.xlarge': worker_count = 8
      else 
        worker_count = 2
      end
    end
    
    worker_name = "delayed_job"
    
    # The symlink is created in /data/app_name/current/tmp/pids -> /data/app_name/shared/pids, but shared/pids doesn't seem to be?
    directory "/data/#{app_name}/shared/pids" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0755
    end

    worker_count.times do |count|
      template "/etc/monit.d/delayed_job_worker#{count+1}.#{app_name}.monitrc" do
        backup 0
        source "delayed_job_worker.monitrc.erb"
        owner "root"
        group "root"
        mode 0644
        variables({
          :app_name => app_name,
          :user => node[:owner_name],
          :worker_name => [worker_name, (count+1).to_s].join,
          :framework_env => node[:environment][:framework_env]
        })
      end
    end
    
    bash "monit-reload-restart" do
       user "root"
       code "monit reload && monit"
    end
      
  end
  

end
