
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
# that works like LorisAssemblyNativeSshDataProvider, except
# the convention for files is slightly different.
#
#     dp_base_path/{numid}/{visit}/mri/native/{arb1}_{numid}_{visit}_{arb2}.mnc
#
# where:
#
#     {arb1} and {arb2} are arbitrary components in the basename
#     {numid} is a 6-digit string
#     {visit} is either "Initial_MRI" or a string matching
#             /^(lego|human)_phantom_(L1|SD)_([A-Z]{3,4})_YYYYMMDD(_(12CH|32CH))?$/
#
# For the list of API methods, see the DataProvider superclass.
#
class LorisCcnaPhantomAssemblyNativeSshDataProvider < LorisAssemblyNativeSshDataProvider

  Revision_info=CbrainFileRevision[__FILE__] #:nodoc:

  private

  # Returns true if the given +userfile+ is named according
  # to the LORIS CCNA Phantom convention for integration with CBRAIN,
  # which means we can find a subject ID and a visit ID.
  #
  # Example: 'ibis_417879_Initial_MRI_t1w_001.mnc'
  #          'ibis_123456_lego_phantom_SD_ABCD_20001212_12CH_t1w_0183.mnc
  #
  # The visit ID can be a complex string with underscores in it.
  # See the regex in the code.
  #
  # Returns the subject ID and the visit ID if the convention
  # is respected; for the example, the "417879" and "V06" parts.
  def named_according_to_LORIS_convention?(userfile)
    if userfile.name =~ /\A
                             [a-zA-Z0-9]+            # arbitrary prefix
                             _(\d\d\d\d\d\d)         # $1 Subject ID
                             _(Initial_MRI|          # $2 Visit, one of "Initial_MRI" or ...
                               (lego|human)
                               _phantom
                               _(L1|SD)
                               _([A-Z]{3,4})         # three or four uppercase letters
                               _\d\d\d\d \d\d \d\d   # year month day
                               (_(12CH|32CH))?       # optional suffix of Visit
                              )
                        /x
      [ Regexp.last_match[1], Regexp.last_match[2] ]
    end
  end

end

