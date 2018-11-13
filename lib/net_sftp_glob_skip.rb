
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

require 'net/sftp'

module Net; module SFTP; module Operations

class Dir

    # The method works like glob() except it will silently
    # ignore permission errors in subdirectories while scanning.
    # This implementation is a modification of glob() and is really
    # dependent on the other method entries().
    def glob_skip(path, pattern, flags=0)
      flags |= ::File::FNM_PATHNAME
      path = path.chop if path[-1,1] == "/"

      results = [] unless block_given?
      queue = entries(path).reject { |e| e.name == "." || e.name == ".." }
      while queue.any?
        entry = queue.shift

        if entry.directory? && !%w(. ..).include?(::File.basename(entry.name))
          # The following three lines differ from the default 'glob' method
          subentries = entries("#{path}/#{entry.name}").to_a rescue []
          subentries.reject! { |e| e.name == "." || e.name == ".." }
          queue += subentries.map do |e|
            e.name.replace("#{entry.name}/#{e.name}")
            e
          end
        end

        if ::File.fnmatch(pattern, entry.name, flags)
          if block_given?
            yield entry
          else
            results << entry
          end
        end
      end

      return results unless block_given?
    end

end

end ; end ; end

