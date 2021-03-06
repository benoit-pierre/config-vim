
require 'find'

def load_skeleton_snippets(directory, *filetypes)

  expand "keyword\t" do

    skel_dir = VIM::evaluate('g:yasnippets_skeletons')

    begin

      cwd = Dir.pwd

      Dir.chdir(skel_dir)

      Find.find(directory) { |skel|

        next if File.directory?(skel)
        next unless File.readable?(skel)

        #VIM::message(skel)

        args = [ "<%=#{skel}>" ]
        args.concat(filetypes)
        args << skel

        defsksnippet(*args)

      } if File.directory?(directory)

    ensure

      Dir.chdir(cwd)

    end if skel_dir

  end

end

load_skeleton_snippets('general', :all)

Dir.glob(File.join(ENV['USERVIM'], 'snippets', '*.rb')) { |entry|

  begin
    load(entry)
  rescue
    puts "error loading: #{entry}: #{$!} [#{$!.class}]"
    puts $@
  end
}
