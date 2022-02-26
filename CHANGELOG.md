## 0.0.6
- Inserting a table now turns it into a draft (this will hopefully be the last time that I mess with this behaviour)
- Drafts are now frozen after the producer function executes
- Added `state.draft.getState`

## 0.0.5
- Inserting a table now keeps it as a non-draft table
- Fixed a bug where swapping a key's value with a draft or table where there was already a draft did not render changes

## 0.0.4
- Inserting a table now turns it into a draft
- Fixed a bug where drafts would not merge correctly if a new key was added and its value was a table

## 0.0.3
- Added `state.draft.isDraft`

## 0.0.2
- Added `state.draft.getRef`

## 0.0.1
- Initial version