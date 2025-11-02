# umka-mode

[Emacs](https://www.gnu.org/software/emacs/) Major Mode for [Umka](https://github.com/vtereshkov/umka-lang) Programming Language.

## Installing locally

Put [umka-mode.el](./umka-mode.el) to some folder `/path/to/umka/`. Add this to your `.emacs`:

```el
;; Adding `/path/to/umka` to load-path so `require` can find it
(add-to-list 'load-path "/path/to/umka/")
;; Importing umka-mode
(require 'umka-mode)
```

*TODO: feel free to submit this package to [MELPA](https://melpa.org/) or what not*
