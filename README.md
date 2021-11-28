# NuGet Unit Tests

| Column | Comment |
|--------|---------|
| **X**  | `-ExcludeVersion` |
| **C**  | Use `packages.config` |
| **S**  | `-PackageSaveMode`. `N`: `nupkg`, `Y`: `nuspec`. |
| **1**  | First Time Install Success |
| **2**  | Second Time Install NOOP |
| **3**  | Install Newer Version Success |
| **4**  | Install Older Version Success |


## 6.0.0

| X | C | S | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|---|
| N | N | N | Y | Y | Y | Y |
| N | N | Y | Y | Y | Y | Y |
| N | Y | N | Y | Y | Y | Y |
| N | Y | Y | Y | Y | Y | Y |
| Y | N | N | Y | Y | Y | N |
| Y | N | Y | Y | Y | N | N |
| Y | Y | N | Y | Y | N | N |
| Y | Y | Y | Y | Y | N | N |


## 5.11.0

| X | C | S | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|---|
| N | N | N | Y | Y | Y | Y |
| N | N | Y | Y | N | Y | Y |
| N | Y | N | Y | Y | Y | Y |
| N | Y | Y | N | N | N | N |
| Y | N | N | Y | Y | Y | N |
| Y | N | Y | Y | Y | N | N |
| Y | Y | N | Y | Y | N | N |
| Y | Y | Y | N | N | N | N |


- **XN-CN-SY@2**: `-PackageSaveMode nuspec` always reinstalls. https://github.com/NuGet/Home/issues/2402.
- **CY-SY**: `packages.config` does not honor `-PackageSaveMode nuspec`. https://github.com/NuGet/Home/issues/11018.
- **XY-CN-SY@3**: `-ExcludeVersion` with `-PackageSaveMode nuspec` cannot upgrade. https://github.com/NuGet/Home/issues/11016.
- **XY-CY-SN@3**: `-ExcludeVersion` with `packages.config` cannot upgrade. https://github.com/NuGet/Home/issues/11017.
- **XY@4**: `-ExcludeVersion` cannot downgrade. https://github.com/NuGet/Home/issues/10437.
