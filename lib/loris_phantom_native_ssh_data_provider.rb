
#
# CBRAIN Project
#
# Copyright (C) 2008-2012
# The Royal Institution for the Advancement of Learning
# McGill University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Contains the implementation of glob_skip()
require_relative 'net_sftp_glob_skip'

class LorisPhantomNativeSshDataProvider < LorisAssemblyNativeSshDataProvider

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  FILE_NAME_REGEX     = /\A
                              (\d\d\d\d\d\d)         # $1 Subject ID
                             _(Initial_MRI|          # $2 Visit, one of "Initial_MRI" or ...
                               (lego|human)
                               _phantom
                               _(L1|SD)
                               _([A-Z]{3,4})         # three or four uppercase letters
                               _\d\d\d\d \d\d \d\d   # year month day
                               (_(12CH|32CH))?       # optional suffix of Visit
                              )
                         \z
                        /x

  def impl_provider_erase(userfile) #:nodoc:
    cb_error "Files on this data provider cannot be erased."
  end

  def impl_sync_to_provider(userfile) #:nodoc:
    cb_error "Files on this data provider cannot be modified."
  end

  def impl_provider_list_all(user=nil) #:nodoc:
    list = []
    attlist = [ 'symbolic_type', 'size', 'permissions',
                'uid',  'gid',  'owner', 'group',
                'atime', 'ctime', 'mtime' ]
    self.master # triggers unlocking the agent
    Net::SFTP.start(remote_host,remote_user, :port => (remote_port.presence || 22), :auth_methods => [ 'publickey' ] ) do |sftp|
      sftp.dir.glob_skip(self.browse_remote_dir(user).to_s, "*/*") do |entry| # glob enforce 6 digits
        attributes = entry.attributes

        type = attributes.symbolic_type
        next if type != :directory
        next if entry.name == "." || entry.name == ".."
        next if is_excluded?(entry.name) # in DataProvider

        name = entry.name.gsub("/","_")
        next unless name =~ FILE_NAME_REGEX

        fileinfo               = FileInfo.new
        fileinfo.name          = name

        bad_attributes = []
        attlist.each do |meth|
          begin
            val = attributes.send(meth)
            fileinfo.send("#{meth}=", val)
          rescue => e
            bad_attributes << meth
          end
        end
        attlist -= bad_attributes unless bad_attributes.empty?

        list << fileinfo
      end
    end
    list.sort! { |a,b| a.name <=> b.name }
    list
  end

  # This method overrides the method in the immediate
  # superclass SshDataProvider.
  def provider_full_path(userfile) #:nodoc:
    basename    = userfile.name
    subid,visid = named_according_to_LORIS_convention!(userfile)
    Pathname.new(remote_dir) + subid + visid
  end



  private

  # If the given +userfile+ is named according
  # to the LORIS CCNA Phantom convention for integration with CBRAIN,
  # which means we can find a subject ID and a visit ID.
  #
  # Example: '417879_lego_phantom_L1_RRI_20170227c'
  #          '876914_lego_phantom_L1_DOUG_20170306'
  #
  # The visit ID can be a complex string with underscores in it.
  # See the regex in the code.
  #
  # Returns the subject ID and the visit ID if the convention
  # is respected; for the example, the "876914" and "lego_phantom_L1_DOUG_20170306 " parts.
  def named_according_to_LORIS_convention?(userfile)
    if userfile.name =~ FILE_NAME_REGEX
      [ Regexp.last_match[1], Regexp.last_match[2] ]
    end
  end

end
