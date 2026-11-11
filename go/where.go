package noosh24

import (
	"fmt"
	"math"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var fieldPattern = regexp.MustCompile(`^[A-Za-z][A-Za-z0-9_.]*$`)

type Condition interface {
	condition() (string, error)
}

type RawWhere string

func (w RawWhere) condition() (string, error) {
	return string(w), nil
}

type Date struct {
	Year  int
	Month time.Month
	Day   int
}

func NewDate(year int, month time.Month, day int) Date {
	return Date{Year: year, Month: month, Day: day}
}

func DateOf(t time.Time) Date {
	y, m, d := t.Date()
	return Date{Year: y, Month: m, Day: d}
}

func (d Date) String() string {
	return fmt.Sprintf("%04d-%02d-%02d", d.Year, int(d.Month), d.Day)
}

type Where struct {
	conditions []string
	err        error
}

func NewWhere() *Where {
	return &Where{}
}

func (w *Where) Eq(field string, value any) *Where  { return w.add(field, "=", value) }
func (w *Where) Ne(field string, value any) *Where  { return w.add(field, "!=", value) }
func (w *Where) Gt(field string, value any) *Where  { return w.add(field, ">", value) }
func (w *Where) Gte(field string, value any) *Where { return w.add(field, ">=", value) }
func (w *Where) Lt(field string, value any) *Where  { return w.add(field, "<", value) }
func (w *Where) Lte(field string, value any) *Where { return w.add(field, "<=", value) }

func (w *Where) In(field string, values ...any) *Where {
	if w.err != nil {
		return w
	}
	if err := checkField(field); err != nil {
		w.err = err
		return w
	}
	if len(values) == 0 {
		w.err = fmt.Errorf("%w: In(%q) needs at least one value", ErrInvalidArgument, field)
		return w
	}
	parts := make([]string, len(values))
	for i, v := range values {
		text, err := Literal(v)
		if err != nil {
			w.err = err
			return w
		}
		parts[i] = text
	}
	w.conditions = append(w.conditions, field+" in ("+strings.Join(parts, ", ")+")")
	return w
}

func (w *Where) Err() error {
	return w.err
}

func (w *Where) Build() (string, error) {
	if w.err != nil {
		return "", w.err
	}
	return w.String(), nil
}

func (w *Where) String() string {
	return strings.Join(w.conditions, " AND ")
}

func (w *Where) condition() (string, error) {
	if w == nil {
		return "", nil
	}
	return w.Build()
}

func (w *Where) add(field, operator string, value any) *Where {
	if w.err != nil {
		return w
	}
	if err := checkField(field); err != nil {
		w.err = err
		return w
	}
	text, err := Literal(value)
	if err != nil {
		w.err = err
		return w
	}
	w.conditions = append(w.conditions, field+" "+operator+" "+text)
	return w
}

func checkField(field string) error {
	if !fieldPattern.MatchString(field) {
		return fmt.Errorf("%w: %q is not a field name", ErrInvalidArgument, field)
	}
	return nil
}

func Literal(value any) (string, error) {
	switch v := value.(type) {
	case nil:
		return "", fmt.Errorf("%w: where takes no null values", ErrInvalidArgument)
	case string:
		return "'" + strings.ReplaceAll(v, "'", "''") + "'", nil
	case bool:
		return strconv.FormatBool(v), nil
	case int:
		return strconv.FormatInt(int64(v), 10), nil
	case int8:
		return strconv.FormatInt(int64(v), 10), nil
	case int16:
		return strconv.FormatInt(int64(v), 10), nil
	case int32:
		return strconv.FormatInt(int64(v), 10), nil
	case int64:
		return strconv.FormatInt(v, 10), nil
	case uint:
		return strconv.FormatUint(uint64(v), 10), nil
	case uint8:
		return strconv.FormatUint(uint64(v), 10), nil
	case uint16:
		return strconv.FormatUint(uint64(v), 10), nil
	case uint32:
		return strconv.FormatUint(uint64(v), 10), nil
	case uint64:
		return strconv.FormatUint(v, 10), nil
	case float32:
		return formatFloat(float64(v), 32)
	case float64:
		return formatFloat(v, 64)
	case time.Time:
		if v.IsZero() {
			return "", fmt.Errorf("%w: where got a zero time.Time", ErrInvalidArgument)
		}
		return "'" + v.Format(time.RFC3339Nano) + "'", nil
	case *time.Time:
		if v == nil {
			return "", fmt.Errorf("%w: where takes no null values", ErrInvalidArgument)
		}
		return Literal(*v)
	case Date:
		return "'" + v.String() + "'", nil
	default:
		return "", fmt.Errorf("%w: where takes strings, numbers, booleans, time.Time and Date, not %T", ErrInvalidArgument, value)
	}
}

func formatFloat(v float64, bits int) (string, error) {
	if math.IsNaN(v) || math.IsInf(v, 0) {
		return "", fmt.Errorf("%w: numbers in where must be finite", ErrInvalidArgument)
	}
	return strconv.FormatFloat(v, 'f', -1, bits), nil
}
