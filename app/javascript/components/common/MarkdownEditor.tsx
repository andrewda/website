import React, { useCallback, useMemo } from 'react'
import SimpleMDE, { SimpleMDEReactProps } from 'react-simplemde-editor'
import { sendRequest } from '../../utils/send-request'

export type MarkdownEditorHandle = {
  value: (value: string | void) => string | void
  focus: () => void
}

export const MarkdownEditor = ({
  contextId,
  onChange = () => {},
  editorDidMount,
  url = document.querySelector<HTMLMetaElement>(
    'meta[name="parse-markdown-url"]'
  )?.content,
  defaultValue = '',
  value = '',
  options = {},
}: {
  contextId?: string
  url?: string
  editorDidMount?: (editor: MarkdownEditorHandle) => void
  defaultValue?: string
  value?: string
  onChange?: (value: string) => void
  options?: EasyMDE.Options
}): JSX.Element => {
  const getInstance = useCallback(
    (editor) => {
      if (!editorDidMount) {
        return
      }

      editorDidMount({
        value: editor.value.bind(editor),
        focus: () => {
          editor.codemirror.focus()
          editor.codemirror.setCursor(editor.codemirror.lineCount(), 0)
        },
      })
    },
    [editorDidMount]
  )

  const editorOptions = useMemo<SimpleMDEReactProps['options']>(() => {
    return {
      autosave: contextId
        ? { enabled: true, uniqueId: contextId, delay: 1000 }
        : undefined,
      autoRefresh: true,
      blockStyles: {
        italic: '_',
      },
      indentWithTabs: false,
      toolbar: [
        'heading',
        'bold',
        'italic',
        'quote',
        'code',
        'link',
        'unordered-list',
        'ordered-list',
        'preview',
      ],
      status: ['autosave'],
      previewRender: (markdown, preview) => {
        if (!url) {
          return 'Preview unavailable'
        }

        const { fetch } = sendRequest<{ html: string }>({
          endpoint: url,
          method: 'POST',
          body: JSON.stringify({
            parse_options: {
              strip_h1: false,
              lower_heading_levels_by: 2,
            },
            markdown: markdown,
          }),
        })

        fetch
          .then((response) => {
            preview.innerHTML = `<div class="c-textual-content --small">${response.html}</div>`
          })
          .catch(() => {
            preview.innerHTML = '<p>Unable to parse markdown</p>'
          })

        return 'Loading...'
      },
      ...options,
    }
  }, [contextId, JSON.stringify(options), url])

  return (
    <SimpleMDE
      value={value}
      defaultValue={defaultValue}
      getMdeInstance={getInstance}
      onChange={onChange}
      options={editorOptions}
    />
  )
}
