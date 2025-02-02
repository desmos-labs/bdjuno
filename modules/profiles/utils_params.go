package profiles

import (
	"fmt"

	"github.com/rs/zerolog/log"

	"github.com/forbole/bdjuno/v4/types"
)

// UpdateParams gets the profiles params for the given height, and stores them inside the database
func (m *Module) UpdateParams(height int64) error {
	log.Debug().Str("module", "profiles").Int64("height", height).Msg("updating params")

	params, err := m.source.GetParams(height)
	if err != nil {
		return fmt.Errorf("error while getting params: %s", err)
	}

	return m.db.SaveProfilesParams(types.NewProfilesParams(params, height))
}
