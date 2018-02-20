
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

# LORIS subject model
#
# Essentially a subdirectory named after the subject ID
# and the visit ID, with files underneath. E.g.
#
# For a LorisBySubjectAndVisit named "212396_v12", the
# content would be a set of minc files like this:
# 
#   212396_v12/mri/native/ibis_212396_v12_t1w_001.mnc
#   212396_v12/mri/native/ibis_212396_v12_t2w_001.mnc
#   etc
class LorisBySubjectAndVisit < FileCollection

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  def self.pretty_type #:nodoc:
    "Loris by Subject and Visit"
  end

  def self.file_name_pattern #:nodoc:
    /\A
      (\d\d\d\d\d\d)         # $1 Subject ID
     _(Initial_MRI|          # $2 Visit, one of "Initial_MRI" or ...
       (lego|human)
       _phantom
       _(L1|SD)
       _([A-Z]{3,4})         # three or four uppercase letters
       _\d\d\d\d \d\d \d\d   # year month day
       (_(12CH|32CH))?       # optional suffix of Visit
      )
    /x
  end

end

