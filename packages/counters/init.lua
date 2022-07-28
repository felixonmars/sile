local base = require("packages.base")

local package = pl.class(base)
package._name = "counters"

SILE.formatCounter = function (counter)
  SU.deprecated("SILE.formatCounter", "class:formatCounter", "0.13.0", "0.15.0")
  return package.formatCounter(nil, counter)
end

SILE.formatMultilevelCounter = function (counter, options)
  SU.deprecated("SILE.formatMultilevelCounter", "class:formatMultilevelCounter", "0.13.0", "0.15.0")
  return package.formatMultilevelCounter(nil, counter, options)
end

local function getCounter (_, id)
  if not SILE.scratch.counters[id] then
    SILE.scratch.counters[id] = {
      value = 0,
      display = "arabic",
      format = package.formatCounter
    }
  end
  return SILE.scratch.counters[id]
end

local function getMultilevelCounter (_, id)
  local counter = SILE.scratch.counters[id]
  if not counter then
    counter = {
      value= { 0 },
      display= { "arabic" },
      format = package.formatMultilevelCounter
    }
    SILE.scratch.counters[id] = counter
  end
  return counter
end

function package.formatCounter (_, counter)
  return SU.formatNumber(counter.value, counter.display)
end

function package:formatMultilevelCounter (counter, options)
  local maxlevel = options and options.level or #counter.value
  local minlevel = options and options.minlevel or 1
  local out = {}
  for x = minlevel, maxlevel do
    out[x - minlevel + 1] = self:formatCounter({ display = counter.display[x], value = counter.value[x] })
  end
  return table.concat(out, ".")
end

function package:_init ()
  base._init(self)
  if not SILE.scratch.counters then
    SILE.scratch.counters = {}
  end
  self:export("getCounter", getCounter)
  self:export("getMultilevelCounter", getMultilevelCounter)
  self:deprecatedExport("formatCounter", self.formatCounter)
  self:deprecatedExport("formatMultilevelCounter", self.formatMultilevelCounter)
end

function package:registerCommands ()

  self:registerCommand("increment-counter", function (options, _)
    local counter = self.class:getCounter(options.id)
    if (options["set-to"]) then
      counter.value = tonumber(options["set-to"])
    else
      counter.value = counter.value + 1
    end
    if options.display then counter.display = options.display end
  end, "Increments the counter named by the <id> option")

  self:registerCommand("set-counter", function (options, _)
    local counter = self.class:getCounter(options.id)
    if options.value then counter.value = tonumber(options.value) end
    if options.display then counter.display = options.display end
  end, "Sets the counter named by the <id> option to <value>; sets its display type (roman/Roman/arabic) to type <display>.")


  self:registerCommand("show-counter", function (options, _)
    local counter = self.class:getCounter(options.id)
    if options.display then counter.display = options.display end
    SILE.typesetter:setpar(self:formatCounter(counter))
  end, "Outputs the value of counter <id>, optionally displaying it with the <display> format.")

  self:registerCommand("increment-multilevel-counter", function (options, _)
    local counter = self.class:getMultilevelCounter(options.id)
    local currentLevel = #counter.value
    local level = tonumber(options.level) or currentLevel
    if level == currentLevel then
      counter.value[level] = counter.value[level] + 1
    elseif level > currentLevel then
      while level > currentLevel do
        currentLevel = currentLevel + 1
        counter.value[currentLevel] = (options.reset == false) and counter.value[currentLevel -1 ] or 1
        counter.display[currentLevel] = counter.display[currentLevel - 1]
      end
    else -- level < currentLevel
      counter.value[level] = counter.value[level] + 1
      while currentLevel > level do
        if not (options.reset == false) then counter.value[currentLevel] = nil end
        counter.display[currentLevel] = nil
        currentLevel = currentLevel - 1
      end
    end
    if options.display then counter.display[currentLevel] = options.display end
  end)

  self:registerCommand("show-multilevel-counter", function (options, _)
    local counter = self.class:getMultilevelCounter(options.id)
    if options.display then counter.display[#counter.value] = options.display end

    SILE.typesetter:typeset(self:formatMultilevelCounter(counter, options))
  end, "Outputs the value of the multilevel counter <id>, optionally displaying it with the <display> format.")

end

package.documentation = [[
\begin{document}

Various parts of SILE such as the \autodoc:package{footnotes} package and the sectioning commands keep a counter of things going on: the current footnote number, the chapter number, and so on.
The counters package allows you to set up, increment and typeset named counters.
It provides the following commands:

\begin{itemize}
\item{\autodoc:command{\set-counter[id=<counter-name>, value=<value>]} — sets the counter with the specified name to the given value.}
\item{\autodoc:command{\increment-counter[id=<counter-name>]} — does the same as \autodoc:command{\set-counter} except that when no \autodoc:parameter{value} parameter is given, the counter is incremented by one.}
\item{\autodoc:command{\show-counter[id=<counter-name>]} — this typesets the value of the counter according to the counter’s declared display type.}
\end{itemize}

All of the commands in the counters package take an optional \autodoc:parameter{display=<display-type>} parameter to set the \em{display type} of the counter.

The available built-in display types are:

\begin{itemize}
\item{\code{arabic}, the default;}
\item{\code{alpha}, for lower-case alphabetic counting;}
\item{\code{Alpha}, for upper-case alphabetic counting;}
\item{\code{roman}, for lower-case Roman numerals; and,}
\item{\code{Roman} for upper-case Roman numerals.}
\end{itemize}

The ICU library also provides ways of formatting numbers in global (non-Latin) scripts.
You can use any of the display types in this list: \url{http://www.unicode.org/repos/cldr/tags/latest/common/bcp47/number.xml}.
For example, \autodoc:parameter{display=beng} will format your numbers in Bengali digits.

So, for example, the following SILE code:

\begin{verbatim}
\line
\\set-counter[id=mycounter, value=2]
\\show-counter[id=mycounter]

\\increment-counter[id=mycounter]
\\show-counter[id=mycounter, display=roman]
\line
\end{verbatim}

produces:

\line
\examplefont{2

\noindent{}iii}
\line
\end{document}
]]

return package
