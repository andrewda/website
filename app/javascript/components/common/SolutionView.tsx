import React, { useState } from 'react'
import { Iteration, File } from '../types'
import { FetchingBoundary } from '../FetchingBoundary'
import { ResultsZone } from '../ResultsZone'
import { IterationsList } from '../mentoring/session/IterationsList'
import { FilePanel } from '../mentoring/session/FilePanel'
import {
  IterationSummary,
  IterationSummaryWithWebsockets,
} from '../track/IterationSummary'
import { usePaginatedRequestQuery } from '../../hooks/request-query'
import { PublishSettings } from '../student/published-solution/PublishSettings'

export type Links = {
  changeIteration?: string
  unpublish?: string
}

export type Props = {
  iterations: readonly Iteration[]
  publishedIterationIdx: number | null
  language: string
  indentSize: number
  outOfDate: boolean
  links: Links
}

const DEFAULT_ERROR = new Error('Unable to load files')

export const SolutionView = ({
  iterations,
  publishedIterationIdx,
  language,
  indentSize,
  outOfDate,
  links,
}: Props): JSX.Element => {
  const [currentIteration, setCurrentIteration] = useState(
    iterations[iterations.length - 1]
  )
  const { resolvedData, error, status, isFetching } = usePaginatedRequestQuery<{
    files: File[]
  }>(currentIteration.links.files, {
    endpoint: currentIteration.links.files,
    options: {},
  })

  return (
    <div className="c-solution-iterations">
      <IterationSummaryWithWebsockets
        iteration={currentIteration}
        OutOfDateNotice={
          outOfDate ? <IterationSummary.OutOfDateNotice /> : null
        }
        showSubmissionMethod={true}
        showTestsStatusAsButton={true}
        showFeedbackIndicator={false}
      />
      <ResultsZone isFetching={isFetching}>
        <FetchingBoundary
          error={error}
          status={status}
          defaultError={DEFAULT_ERROR}
        >
          {resolvedData ? (
            <FilePanel
              files={resolvedData.files}
              language={language}
              indentSize={indentSize}
            />
          ) : null}
        </FetchingBoundary>
      </ResultsZone>
      <footer className="c-iterations-footer">
        {iterations.length > 1 ? (
          <IterationsList
            iterations={iterations}
            onClick={setCurrentIteration}
            current={currentIteration}
          />
        ) : null}
        {links.changeIteration && links.unpublish ? (
          <PublishSettings
            links={{
              changeIteration: links.changeIteration,
              unpublish: links.unpublish,
            }}
            publishedIterationIdx={publishedIterationIdx}
            iterations={iterations}
            redirectType="public"
          />
        ) : null}
      </footer>
    </div>
  )
}
