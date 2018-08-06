
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

#
# This class provides an implementation for a data provider
# where the remote files are accessed following the LORIS
# convention for assembly/native files.
#
#     /data/ibis/data/assembly/417879/V06/mri/native/ibis_417879_V06_t1w_001.mnc
#
# where the components "417879", and "V06" are expected to always match
# their counterparts in the filename.
#
# For the list of API methods, see the DataProvider superclass.
#
class LorisAssemblyNativeSshDataProvider < SshDataProvider

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  # This returns the category of the data provider
  def self.pretty_category_name #:nodoc:
    "Application Specific"
  end

  def is_browsable?(by_user = nil) #:nodoc:
    return true if by_user.blank? || self.meta[:browse_gid].blank?
    return true if by_user.is_a?(AdminUser) || by_user.id == self.user_id
    by_user.is_member_of_group(self.meta[:browse_gid].to_i)
  end

  def allow_file_owner_change? #:nodoc:
    true
  end

  def content_storage_shared_between_users? #:nodoc:
    true # yep, to avoid two users crushing each other's files
  end

  def impl_sync_to_provider(userfile) #:nodoc:
    subid,visid = named_according_to_LORIS_convention!(userfile)
    userdir = Pathname.new(remote_dir)
    level1  = userdir                  + subid
    level2  = level1                   + visid
    level3  = level2                   + "mri"
    if userfile.is_a?(MincFile)
      level4  = level3                 + "native"
      level5  = ""
    else
      level4  = level3                 + "processed"
      level5  = level4                 + userfile.class.to_s
    end
    mkdir_command = "mkdir #{level1.to_s.bash_escape} #{level2.to_s.bash_escape} #{level3.to_s.bash_escape} #{level4.to_s.bash_escape} #{level5.to_s.bash_escape} >/dev/null 2>&1"
    remote_bash_this(mkdir_command)
    super(userfile)
  end

  def impl_provider_erase(userfile) #:nodoc:
    named_according_to_LORIS_convention!(userfile)
    remotefull = provider_full_path(userfile)
    rm_command = "/bin/rm #{remotefull.to_s.bash_escape}"
    remote_bash_this(rm_command)
    true
  end

  def impl_provider_rename(userfile,newname)  #:nodoc:
    cb_error "Files on this data provider cannot be renamed."
  end

  def impl_provider_list_all(user=nil) #:nodoc:
    list = []
    attlist = [ 'symbolic_type', 'size', 'permissions',
                'uid',  'gid',  'owner', 'group',
                'atime', 'ctime', 'mtime' ]
    self.master # triggers unlocking the agent
    Net::SFTP.start(remote_host,remote_user, :port => (remote_port.presence || 22), :auth_methods => [ 'publickey' ] ) do |sftp|
      sftp.dir.glob(self.browse_remote_dir(user).to_s, "*/*/mri/native/*.mnc*") do |entry|
        attributes = entry.attributes

        type = attributes.symbolic_type
        next if type != :regular
        next if entry.name == "." || entry.name == ".."
        next if is_excluded?(entry.name) # in DataProvider

        fileinfo               = FileInfo.new
        fileinfo.name          = File.basename(entry.name)

        bad_attributes = []
        attlist.each do |meth|
          begin
            val = attributes.send(meth)
            fileinfo.send("#{meth}=", val)
          rescue => e
            #puts "Method #{meth} not supported: #{e.message}"
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
    basename = userfile.name
    subid,visid = named_according_to_LORIS_convention!(userfile)
    if userfile.is_a?(MincFile)
      Pathname.new(remote_dir) + subid + visid + "mri" + "native" + basename
    else
      Pathname.new(remote_dir) + subid + visid + "mri" + "processed" + userfile.class.to_s + basename
    end
  end

  private

  # Checks that the given +userfile+ is named according
  # to the LORIS convention for integration with CBRAIN,
  # which means we can find a subject ID and a visit ID.
  # Raises an exception if it's not the case.
  #
  # Example: 'ibis_417879_V06_t1w_001.mnc'
  #
  # Returns the subject ID and the visit ID if the convention
  # is respected; for the example, the "417879" and "V06" parts.
  def named_according_to_LORIS_convention!(userfile)
    named_according_to_LORIS_convention?(userfile) or
    raise "Basename '#{userfile.name}' does not match the LORIS convention."
  end

  # Returns true if the given +userfile+ is named according
  # to the LORIS convention for integration with CBRAIN,
  # which means we can find a subject ID and a visit ID.
  #
  # Example: 'ibis_417879_V06_t1w_001.mnc'
  #
  # Returns the subject ID and the visit ID if the convention
  # is respected; for the example, the "417879" and "V06" parts.
  def named_according_to_LORIS_convention?(userfile)
    if userfile.name =~ /\A[a-zA-Z0-9]+_([a-zA-Z0-9]+)_([a-zA-Z0-9]+)/
      [ Regexp.last_match[1], Regexp.last_match[2] ]
    end
  end

end

