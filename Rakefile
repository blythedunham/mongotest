# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'


namespace 'views' do
  desc 'Renames all your rhtml views to erb'
  task 'rename' do
    Dir.glob('vendor/plugins/sitealizer/lib/app/views/**/*.rhtml').each do |file|
      puts `mv #{file} #{file.gsub(/\.rhtml$/, '.erb')}`
    end
  end
end
