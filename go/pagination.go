package noosh24

import (
	"context"
	"encoding/json"
	"fmt"
	"iter"
	"strconv"
)

type Expand string

const (
	ExpandModifierGroups Expand = "modifierGroups"
	ExpandTranslations   Expand = "translations"
)

type ListParams struct {
	Limit  int
	Offset int
	Sort   []string
	Where  Condition
	Expand []Expand
}

type Page[T any] struct {
	Items  []T
	Total  int
	Limit  int
	Offset int
}

func (p *Page[T]) HasMore() bool {
	return len(p.Items) > 0 && p.Offset+len(p.Items) < p.Total
}

func (p *Page[T]) NextOffset() int {
	return p.Offset + len(p.Items)
}

type pageOptions struct {
	expand   bool
	paginate bool
}

func (p *ListParams) clone() ListParams {
	if p == nil {
		return ListParams{}
	}
	out := *p
	out.Sort = append([]string(nil), p.Sort...)
	out.Expand = append([]Expand(nil), p.Expand...)
	return out
}

func listQuery(p ListParams, opts pageOptions) ([]queryPair, error) {
	var q []queryPair
	if p.Limit != 0 || opts.paginate {
		q = append(q, queryPair{"limit", strconv.Itoa(p.Limit)})
	}
	if p.Offset != 0 || opts.paginate {
		q = append(q, queryPair{"offset", strconv.Itoa(p.Offset)})
	}
	for _, s := range p.Sort {
		if s != "" {
			q = append(q, queryPair{"sort", s})
		}
	}
	if p.Where != nil {
		text, err := p.Where.condition()
		if err != nil {
			return nil, err
		}
		if text != "" {
			q = append(q, queryPair{"where", text})
		}
	}
	if len(p.Expand) > 0 && !opts.expand {
		return nil, fmt.Errorf("%w: expand is only supported on menu products", ErrInvalidArgument)
	}
	for _, e := range p.Expand {
		if e != "" {
			q = append(q, queryPair{"expand", string(e)})
		}
	}
	return q, nil
}

func expandQuery(expand []Expand) []queryPair {
	var q []queryPair
	for _, e := range expand {
		if e != "" {
			q = append(q, queryPair{"expand", string(e)})
		}
	}
	return q
}

func fetchPage[T any, P decodable[T]](ctx context.Context, c *Client, path string, params ListParams, opts pageOptions) (*Page[T], error) {
	query, err := listQuery(params, opts)
	if err != nil {
		return nil, err
	}
	resp, err := c.do(ctx, request{method: "GET", path: path, query: query, retryable: true})
	if err != nil {
		return nil, err
	}
	f, _ := objectFields(resp.data)
	items := decodeItems[T, P](rawList(f["items"]))
	page := &Page[T]{Items: items, Total: len(items), Limit: params.Limit, Offset: params.Offset}
	if params.Limit == 0 {
		page.Limit = len(items)
	}
	if v := intPtr(f["total"]); v != nil {
		page.Total = *v
	}
	if v := intPtr(f["limit"]); v != nil {
		page.Limit = *v
	}
	if v := intPtr(f["offset"]); v != nil {
		page.Offset = *v
	}
	return page, nil
}

func iterate[T any, P decodable[T]](ctx context.Context, c *Client, path string, params *ListParams, pageSize int, opts pageOptions) iter.Seq2[T, error] {
	start := params.clone()
	if start.Limit == 0 {
		start.Limit = pageSize
	}
	opts.paginate = true
	return func(yield func(T, error) bool) {
		p := start
		for {
			page, err := fetchPage[T, P](ctx, c, path, p, opts)
			if err != nil {
				var zero T
				yield(zero, err)
				return
			}
			for _, item := range page.Items {
				if !yield(item, nil) {
					return
				}
			}
			if !page.HasMore() {
				return
			}
			p.Offset = page.NextOffset()
		}
	}
}

func fetchAll[T any, P decodable[T]](ctx context.Context, c *Client, path string) ([]T, error) {
	resp, err := c.do(ctx, request{method: "GET", path: path, retryable: true})
	if err != nil {
		return nil, err
	}
	f, _ := objectFields(resp.data)
	return decodeItems[T, P](rawList(f["items"])), nil
}

func getOne[T any, P decodable[T]](ctx context.Context, c *Client, path string, query []queryPair) (*T, error) {
	resp, err := c.do(ctx, request{method: "GET", path: path, query: query, retryable: true})
	if err != nil {
		return nil, err
	}
	return decodeOne[T, P](resp.data), nil
}

func decodeOne[T any, P decodable[T]](data json.RawMessage) *T {
	v := new(T)
	if isObject(data) {
		_ = P(v).UnmarshalJSON(data)
	}
	return v
}
