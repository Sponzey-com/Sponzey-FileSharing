# Task 068. Task Checklist Hygiene And Local Gate Status

## Goal

현재 TCP Data Channel 전환 루프에서 완료된 태스크와 남은 release gate gap을 오해 없이 추적할 수 있도록 task 체크리스트와 plan의 현재 상태를 정리한다.

## Scope

- [x] 과거 task 문서의 Stop Conditions를 진행 체크박스가 아닌 일반 bullet로 정리한다.
- [x] `.tasks/plan.md`에 로컬 자동 gate 통과 상태와 남은 수동 smoke 항목을 명시한다.
- [x] diff 검사와 문서 검색으로 미완료 체크박스가 남지 않았는지 확인한다.

## Validation

- [x] `rg -n "\[ \]" .tasks/task0*.md`
- [x] `git diff --check`

## Done Criteria

- [x] 현재 task 문서의 체크박스는 실제 진행상태만 표현한다.
- [x] plan은 로컬 자동 gate 통과와 host/VM smoke 미수행 상태를 분리해 설명한다.
