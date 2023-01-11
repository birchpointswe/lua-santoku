-- A b-tree implementation

-- TODO: Btree based on two tables. The first is
-- a list of indices of free blocks including
-- the furthest open block down the block table.
-- The second is a list of blocks, which are
-- divided into two sections. 1-N contains btree
-- node values, and 2x(1-N) contains an int
-- pointing to the block containing values
-- larger the corresponding value on the first
-- section. Users can configure max block size.
-- As blocks are deleted they are added to the
-- free list and used first for new block
-- creation. A user-callable optimize function
-- can create a new table from the old table (in
-- constant space?) by moving blocks to a new
-- table and updating indices. The resulting
-- table would be fully compact.
--
-- Presumably we can force a rehash during
-- optimize by setting a few new keys in the
-- hash part after freeing blocks in the array
-- part.

local M = {}

return M
