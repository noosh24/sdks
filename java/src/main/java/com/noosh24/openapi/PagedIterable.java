package com.noosh24.openapi;

import java.util.Iterator;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Spliterator;
import java.util.Spliterators;
import java.util.function.Function;
import java.util.stream.Stream;
import java.util.stream.StreamSupport;

public final class PagedIterable<T> implements Iterable<T> {
    private final Function<Integer, Page<T>> fetch;
    private final int startOffset;

    PagedIterable(Function<Integer, Page<T>> fetch, int startOffset) {
        this.fetch = fetch;
        this.startOffset = startOffset;
    }

    @Override
    public Iterator<T> iterator() {
        return new Walker();
    }

    public Stream<T> stream() {
        return StreamSupport.stream(
                () -> Spliterators.spliteratorUnknownSize(iterator(), Spliterator.ORDERED | Spliterator.NONNULL),
                Spliterator.ORDERED | Spliterator.NONNULL,
                false);
    }

    private final class Walker implements Iterator<T> {
        private Iterator<T> buffer = List.<T>of().iterator();
        private int offset = startOffset;
        private boolean done;

        @Override
        public boolean hasNext() {
            while (!buffer.hasNext() && !done) {
                Page<T> page = fetch.apply(offset);
                buffer = page.items().iterator();
                if (page.hasMore()) {
                    offset = page.nextOffset();
                } else {
                    done = true;
                }
            }
            return buffer.hasNext();
        }

        @Override
        public T next() {
            if (!hasNext()) {
                throw new NoSuchElementException();
            }
            return buffer.next();
        }
    }
}
