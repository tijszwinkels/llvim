
" Generic

command! RD :redraw!


" LLM running

" Define the custom command :llm
command! LLM call s:RunLLM("")

" Define the custom command :LLM4
command! LLM4 call s:RunLLM("-m gpt4")

function! s:RunLLM(model_flag)
    " Save the yanked text into a variable
    let l:yanked_text = getreg('0')

    " Save the current buffer number
    " let l:current_buf = bufnr('%')

    " Save the temporary file paths
    let l:temp_in = "/tmp/llm_in.txt"
    let l:temp_out = "/tmp/llm_out.txt"

    " Write the yanked text to the temporary input file
    call writefile(split(l:yanked_text, '\n'), l:temp_in)

    " Run the llm command and pipe the yank buffer through it
    execute "!cat " . l:temp_in . " | llm " . a:model_flag . " | tee " . l:temp_out

    " Read the output back into Vim at the current cursor position
    execute "r " . l:temp_out

    " Add the 'AI: ' prefix to the output
    execute "normal! IAI: "

    " Make the changes undoable in one step
    undojoin
endfunction


" Yanking

" Function to yank text from cursor to next '###' or to the beginning of the file
function! YankToNextHash()
    " Save the current cursor position
    let l:save_cursor = getcurpos()

    " Search for the next '###' sequence in backward direction
    let l:found = search('###', 'bW')

    " If not found, set to the first line
    if l:found == 0
        let l:found = 1
    else
        " Decrement to exclude the line with '###'
        let l:found = l:found + 1
    endif

    " Yank from the found position or beginning to the current line
    execute l:found . "," . l:save_cursor[1] . "yank"

    " Restore the cursor position
    call setpos('.', l:save_cursor)
endfunction


" Define the custom command :yh (yanks backwards until the next ###)
command! YH call YankToNextHash()


command! YC call YankCodeBlock()

function! YankCodeBlock()

    " Save the current cursor position
    let l:save_cursor = getpos('.')

    " Set the pattern for lines starting with '```'
    let l:pattern = '```.*'

    " Search for the line with '```' moving backwards
    let l:found_end = search('```', 'bW')

    " If no line is found, exit the function
    if l:found_end == 0
        return
    endif

    " Move the cursor to the next line starting with '```' (begin of code block)
    let l:found = search('```', 'bW')

    " If there is no closing '```', do nothing
    if l:found == 0
        return
    endif

    " Decrement to exclude the line with '```'
    let l:found_end = l:found_end - 1

    " Yank from the start to the end of the code block
    if l:found+1 <= l:found_end
	execute l:found+1 . "," . l:found_end . "yank"
    endif

    " Go to the closing tag
     call search('```') 

    " Restore the cursor position (Disabled)
    " call setpos('.', l:save_cursor)
    
endfunction 


" Generic code running

" Define the custom command :PY
command! PY call s:RunCode("py")

" Define the custom command :SH
command! SH call s:RunCode("sh")

function! s:RunCode(type)
    " Temporary files
    let l:temp_in = "/tmp/input.txt"
    let l:temp_out = "/tmp/output.txt"

    " Save the current buffer number
    let l:current_buf = bufnr('%')
    let l:command = ''

    " Get the yanked text
    let l:yanked_text = getreg('0')

    " Write the yanked text to the temporary input file
    call writefile(split(l:yanked_text, '\n'), l:temp_in)

    " Choose the interpreter and run it
    if a:type == 'py'
        let l:command = "!python3 -c 'exec(open(\"" . l:temp_in . "\").read())' > " . l:temp_out . " 2>&1"
        let l:prefix = 'I-- Python Output: '
    elseif a:type == 'sh'
        let l:command = "!sh " . l:temp_in . " > " . l:temp_out . " 2>&1"
        let l:prefix = 'I-- Shell Output: '
    endif

    execute l:command

    " Read the output back into Vim at the current cursor position
    execute "r " . l:temp_out

    " Add the prefix to the output
    execute "normal! " . l:prefix
endfunction


" Key mappings
" ctrl-m for yank up till prev ### and run through gpt-3.5
nnoremap <C-m> :execute 'normal! o'<CR>:YH<CR>:LLM<CR>
" ctrl-l for yank up till prev ### and run through gpt-4
nnoremap <C-l> :execute 'normal! o'<CR>:YH<CR>:LLM4<CR>
" ctrl-n for new LLM interaction block
nnoremap <C-n> Go<CR>###<ESC>G
" ctrl-p for prompt
nnoremap <C-p> :read ./default.prompt<CR>']j
" ctrl-x for execute shell
nnoremap <C-x> :execute 'normal! ?^```'<CR>jo<ESC>:sleep 50m<CR>:YC<CR>:SH<CR>


" Copy the contents of the register to a certain file without opening the file
function! RegToFile(filename)
    let l:content = getreg('"')
    call writefile(split(l:content, "\n"), a:filename)
endfunction
command! -nargs=1 -complete=file RegToFile call RegToFile(<f-args>)


" Rename
command! -nargs=1 Rename execute 'saveas ' . <f-args> | silent !rm #
