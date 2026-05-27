# Exptv2 Kotlin Transactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first functional Exptv2 transaction screen: Kotlin Room stores seeded categories and transactions, Flutter reads/writes them through MethodChannel, FAB opens the add transaction menu, and the home body shows filtered logboxes.

**Architecture:** Kotlin owns persistence through a new `expense_tracker.db` Room database and exposes a narrow MethodChannel API on the existing `pushparser/methods` channel. Flutter owns UI state, local filtering, summary-window display, and form validation display, while Kotlin performs DB validation and amount sign normalization.

**Tech Stack:** Flutter/Dart, Kotlin, Android Room, KSP, MethodChannel, Flutter widget tests, existing GitHub Actions APK build.

---

## File Structure

Create Kotlin expense DB package:

- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt` - Room row for cloned transaction logs.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/TransactionCategoryEntity.kt` - Room row for cloned categories.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt` - transaction queries and writes.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/TransactionCategoryDao.kt` - category queries and seed writes.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt` - separate Room database named `expense_tracker.db`.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt` - exact 9 category and 13 transaction seed rows from `expt0926`.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt` - seed, validation, filtering, insert/delete, summary helpers.
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt` - MethodChannel handler methods.
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt` - register `ExpenseMethodChannel` beside current push parser methods.

Create Flutter transaction feature:

- Create: `lib/features/transactions/models/transaction_category.dart` - Dart category model and type normalization.
- Create: `lib/features/transactions/models/transaction_record.dart` - Dart transaction model and formatting helpers.
- Create: `lib/features/transactions/models/transaction_summary.dart` - monthly/yearly/all-time summary values.
- Create: `lib/features/transactions/data/transaction_filter.dart` - immutable filter value object.
- Create: `lib/features/transactions/data/transaction_repository.dart` - typed wrapper around `NativeBridge` expense calls.
- Create: `lib/features/transactions/state/transaction_store.dart` - ChangeNotifier for load, save, filters, summaries.
- Create: `lib/features/transactions/transaction_home_page.dart` - home screen body composition.
- Create: `lib/features/transactions/widgets/transaction_type_pills.dart` - `Bevétel` / `Kiadás` switch.
- Create: `lib/features/transactions/widgets/summary_pill.dart` - swipeable monthly/yearly/all-time pill.
- Create: `lib/features/transactions/widgets/search_pill.dart` - merchant search/filter capsule.
- Create: `lib/features/transactions/widgets/transaction_log_list.dart` - grouped scroll list.
- Create: `lib/features/transactions/widgets/transaction_log_box.dart` - visual logbox and left-swipe fast filter.
- Create: `lib/features/transactions/widgets/add_transaction_sheet.dart` - FAB sheet form.
- Create: `lib/features/transactions/widgets/category_selector_field.dart` - category selector used by the sheet.
- Create: `lib/features/transactions/widgets/date_time_fields.dart` - date/time fields for the sheet.
- Create: `lib/features/transactions/widgets/amount_field.dart` - amount input with `Ft` suffix.

Modify existing Flutter files:

- Modify: `lib/core/theme/app_colors.dart` - add income/expense and slot colors.
- Modify: `lib/main.dart` - share one `NativeBridge` between event store and transaction shell.
- Modify: `lib/exptv2_app.dart` - pass `NativeBridge` into `ExptShell`.
- Modify: `lib/features/shell/expt_shell.dart` - render `TransactionHomePage` for home and route FAB to it.
- Modify: `lib/services/native_bridge.dart` - add expense MethodChannel methods.
- Modify: `test/widget_test.dart` - update home expectations and FAB add transaction coverage.

Create tests:

- Create: `test/transactions/transaction_models_test.dart`
- Create: `test/transactions/transaction_store_test.dart`
- Create: `test/transactions/transaction_widgets_test.dart`
- Modify: `test/widget_test.dart`

---

### Task 1: Dart Transaction Models

**Files:**
- Create: `test/transactions/transaction_models_test.dart`
- Create: `lib/features/transactions/models/transaction_category.dart`
- Create: `lib/features/transactions/models/transaction_record.dart`
- Create: `lib/features/transactions/models/transaction_summary.dart`
- Modify: `lib/core/theme/app_colors.dart`

- [ ] **Step 1: Write failing model tests**

Create `test/transactions/transaction_models_test.dart`:

```dart
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/models/transaction_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TransactionCategory normalizes Hungarian type values', () {
    final income = TransactionCategory.fromMap({
      'transactionCategoryID': 5,
      'name': 'Rr',
      'type': 'bevétel',
      'colorSlot': 2,
      'iconSlot': 0,
      'backgroundColor': '#3b82f6',
      'icon': './assets/broccoli.png',
      'notification': null,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
      'originalIcon': null,
    });

    final expense = TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Q',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#dc2626',
      'icon': './assets/example.png',
      'notification': null,
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
      'originalIcon': null,
    });

    expect(income.normalizedType, TransactionType.income);
    expect(expense.normalizedType, TransactionType.expense);
    expect(income.slotColorHex, '#eab308');
  });

  test('TransactionRecord parses native payload and formats display fields', () {
    final record = TransactionRecord.fromMap({
      'id': 250905,
      'date': '2025.09.24',
      'time': '21:56',
      'latitude': null,
      'longitude': null,
      'address': 'Unknown location',
      'merchant': 'Rrteeaawwq',
      'amount': 5555,
      'userAssignedName': 'Gguu',
      'transactionCategoryID': 5,
    });

    expect(record.type, TransactionType.income);
    expect(record.displayMerchant, 'Gguu');
    expect(record.displayAmount, '+5 555 Ft');
    expect(record.displayTime, '21:56');
    expect(record.yearMonthKey, '2025-09');
  });

  test('TransactionSummary calculates income expense and active total', () {
    final records = [
      TransactionRecord.fromMap({
        'id': 250901,
        'date': '2025.09.24',
        'time': '20:31',
        'merchant': 'Tt',
        'amount': -66,
        'userAssignedName': null,
        'transactionCategoryID': 9,
      }),
      TransactionRecord.fromMap({
        'id': 250905,
        'date': '2025.09.24',
        'time': '21:56',
        'merchant': 'Rrteeaawwq',
        'amount': 5555,
        'userAssignedName': 'Gguu',
        'transactionCategoryID': 5,
      }),
    ];

    final summary = TransactionSummary.fromRecords(records);

    expect(summary.income, 5555);
    expect(summary.expense, 66);
    expect(summary.formattedFor(TransactionType.income), '+5 555 Ft');
    expect(summary.formattedFor(TransactionType.expense), '-66 Ft');
  });
}
```

- [ ] **Step 2: Run model tests and verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_models_test.dart'
```

Expected: FAIL because the `features/transactions` model files do not exist.

- [ ] **Step 3: Implement category model**

Create `lib/features/transactions/models/transaction_category.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get nativeValue => switch (this) {
    TransactionType.income => 'income',
    TransactionType.expense => 'expense',
  };

  String get hungarianValue => switch (this) {
    TransactionType.income => 'bevétel',
    TransactionType.expense => 'kiadás',
  };

  String get label => switch (this) {
    TransactionType.income => 'Bevétel',
    TransactionType.expense => 'Kiadás',
  };

  static TransactionType fromAny(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'income' || normalized == 'bevétel') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }
}

class TransactionCategory {
  const TransactionCategory({
    required this.transactionCategoryID,
    required this.name,
    required this.type,
    required this.colorSlot,
    required this.iconSlot,
    required this.backgroundColor,
    required this.icon,
    required this.notification,
    required this.hasLimit,
    required this.limitAmount,
    required this.alertActive,
    required this.isCustomIcon,
    required this.originalIcon,
  });

  final int transactionCategoryID;
  final String name;
  final String type;
  final int? colorSlot;
  final int? iconSlot;
  final String? backgroundColor;
  final String? icon;
  final String? notification;
  final bool hasLimit;
  final double limitAmount;
  final bool alertActive;
  final bool isCustomIcon;
  final String? originalIcon;

  TransactionType get normalizedType => TransactionTypeX.fromAny(type);

  String get slotColorHex {
    final slot = colorSlot;
    if (slot == null) return backgroundColor ?? '#64748b';
    return AppColors.slotColorHex(slot);
  }

  Color get slotColor => AppColors.fromHex(slotColorHex);

  factory TransactionCategory.fromMap(Map<dynamic, dynamic> map) {
    return TransactionCategory(
      transactionCategoryID: _int(map['transactionCategoryID']),
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? 'kiadás',
      colorSlot: _nullableInt(map['colorSlot']),
      iconSlot: _nullableInt(map['iconSlot']),
      backgroundColor: map['backgroundColor']?.toString(),
      icon: map['icon']?.toString(),
      notification: map['notification']?.toString(),
      hasLimit: _bool(map['hasLimit']),
      limitAmount: _double(map['limitAmount']),
      alertActive: _bool(map['alertActive']),
      isCustomIcon: _bool(map['isCustomIcon']),
      originalIcon: map['originalIcon']?.toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'transactionCategoryID': transactionCategoryID,
      'name': name,
      'type': type,
      'colorSlot': colorSlot,
      'iconSlot': iconSlot,
      'backgroundColor': backgroundColor,
      'icon': icon,
      'notification': notification,
      'hasLimit': hasLimit,
      'limitAmount': limitAmount,
      'alertActive': alertActive,
      'isCustomIcon': isCustomIcon,
      'originalIcon': originalIcon,
    };
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
int? _nullableInt(Object? value) => value == null ? null : _int(value);
double _double(Object? value) => value is num ? value.toDouble() : double.parse(value.toString());
bool _bool(Object? value) => value == true || value == 1 || value?.toString() == 'true';
```

- [ ] **Step 4: Extend app colors**

Modify `lib/core/theme/app_colors.dart` by adding these members inside `AppColors`:

```dart
  static const income = Color(0xFF22C55E);
  static const expense = Color(0xFFEF4444);

  static const slotColors = <int, Color>{
    0: Color(0xFFEF4444),
    1: Color(0xFFF97316),
    2: Color(0xFFEAB308),
    3: Color(0xFF84CC16),
    4: Color(0xFF22C55E),
    5: Color(0xFF10B981),
    6: Color(0xFF06B6D4),
    7: Color(0xFF0EA5E9),
    8: Color(0xFF3B82F6),
    9: Color(0xFF6366F1),
    10: Color(0xFF8B5CF6),
    11: Color(0xFFA855F7),
    12: Color(0xFFD946EF),
    13: Color(0xFFEC4899),
    14: Color(0xFFF43F5E),
    15: Color(0xFF6B7280),
    16: Color(0xFF374151),
    17: Color(0xFF1F2937),
    18: Color(0xFF064E3B),
    19: Color(0xFF7C2D12),
    20: Color(0xFF4C1D95),
  };

  static Color slotColor(int slot) => slotColors[slot] ?? gray500;

  static String slotColorHex(int slot) {
    final color = slotColor(slot);
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }

  static Color fromHex(String value) {
    final clean = value.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
```

- [ ] **Step 5: Implement transaction record model**

Create `lib/features/transactions/models/transaction_record.dart`:

```dart
import 'transaction_category.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.merchant,
    required this.amount,
    required this.userAssignedName,
    required this.transactionCategoryID,
  });

  final int id;
  final String date;
  final String time;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String merchant;
  final double amount;
  final String? userAssignedName;
  final int transactionCategoryID;

  TransactionType get type => amount > 0 ? TransactionType.income : TransactionType.expense;
  String get displayMerchant => (userAssignedName?.trim().isNotEmpty ?? false) ? userAssignedName!.trim() : merchant.trim();
  String get displayTime {
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    return time;
  }

  String get yearMonthKey => normalizedDate.length >= 7 ? normalizedDate.substring(0, 7) : normalizedDate;
  String get normalizedDate => date.replaceAll('.', '-');
  String get displayAmount => '${type == TransactionType.income ? '+' : '-'}${formatHuf(amount.abs())}';

  factory TransactionRecord.fromMap(Map<dynamic, dynamic> map) {
    return TransactionRecord(
      id: _int(map['id']),
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      latitude: _nullableDouble(map['latitude']),
      longitude: _nullableDouble(map['longitude']),
      address: map['address']?.toString(),
      merchant: map['merchant']?.toString() ?? '',
      amount: _double(map['amount']),
      userAssignedName: map['userAssignedName']?.toString(),
      transactionCategoryID: _int(map['transactionCategoryID']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'merchant': merchant,
      'amount': amount,
      'userAssignedName': userAssignedName,
      'transactionCategoryID': transactionCategoryID,
    };
  }
}

String formatHuf(num amount) {
  final rounded = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i += 1) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(' ');
  }
  return '${buffer.toString()} Ft';
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
double _double(Object? value) => value is num ? value.toDouble() : double.parse(value.toString());
double? _nullableDouble(Object? value) => value == null ? null : _double(value);
```

- [ ] **Step 6: Implement summary model**

Create `lib/features/transactions/models/transaction_summary.dart`:

```dart
import 'transaction_category.dart';
import 'transaction_record.dart';

class TransactionSummary {
  const TransactionSummary({required this.income, required this.expense});

  final double income;
  final double expense;

  factory TransactionSummary.fromRecords(Iterable<TransactionRecord> records) {
    var income = 0.0;
    var expense = 0.0;
    for (final record in records) {
      if (record.amount > 0) {
        income += record.amount;
      } else {
        expense += record.amount.abs();
      }
    }
    return TransactionSummary(income: income, expense: expense);
  }

  String formattedFor(TransactionType type) {
    return type == TransactionType.income ? '+${formatHuf(income)}' : '-${formatHuf(expense)}';
  }
}
```

- [ ] **Step 7: Run model tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_models_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/core/theme/app_colors.dart lib/features/transactions/models test/transactions/transaction_models_test.dart
git commit -m "feat: add transaction models"
```

---

### Task 2: Kotlin Room Expense Database

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/TransactionCategoryEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTransactionDao.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/TransactionCategoryDao.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`

- [ ] **Step 1: Create transaction entity**

Create `ExpenseTransactionEntity.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "transactions",
    foreignKeys = [
        ForeignKey(
            entity = TransactionCategoryEntity::class,
            parentColumns = ["transactionCategoryID"],
            childColumns = ["transactionCategoryID"],
            onDelete = ForeignKey.RESTRICT,
        ),
    ],
    indices = [
        Index("transactionCategoryID"),
        Index("date"),
        Index("merchant"),
        Index("amount"),
    ],
)
data class ExpenseTransactionEntity(
    @PrimaryKey val id: Int,
    val date: String,
    val time: String,
    val latitude: Double?,
    val longitude: Double?,
    val address: String?,
    val merchant: String,
    val amount: Double,
    val userAssignedName: String?,
    val transactionCategoryID: Int,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "date" to date,
        "time" to time,
        "latitude" to latitude,
        "longitude" to longitude,
        "address" to address,
        "merchant" to merchant,
        "amount" to amount,
        "userAssignedName" to userAssignedName,
        "transactionCategoryID" to transactionCategoryID,
    )
}
```

- [ ] **Step 2: Create category entity**

Create `TransactionCategoryEntity.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "transaction_categories",
    indices = [Index("type")],
)
data class TransactionCategoryEntity(
    @PrimaryKey val transactionCategoryID: Int,
    val name: String,
    val type: String,
    val colorSlot: Int?,
    val iconSlot: Int?,
    val backgroundColor: String?,
    val icon: String?,
    val notification: String?,
    val hasLimit: Boolean,
    val limitAmount: Double,
    val alertActive: Boolean,
    val isCustomIcon: Boolean,
    val originalIcon: String?,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "transactionCategoryID" to transactionCategoryID,
        "name" to name,
        "type" to type,
        "colorSlot" to colorSlot,
        "iconSlot" to iconSlot,
        "backgroundColor" to backgroundColor,
        "icon" to icon,
        "notification" to notification,
        "hasLimit" to hasLimit,
        "limitAmount" to limitAmount,
        "alertActive" to alertActive,
        "isCustomIcon" to isCustomIcon,
        "originalIcon" to originalIcon,
    )
}
```

- [ ] **Step 3: Create DAOs**

Create `ExpenseTransactionDao.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface ExpenseTransactionDao {
    @Query("SELECT COUNT(*) FROM transactions")
    suspend fun count(): Int

    @Query("SELECT * FROM transactions ORDER BY date DESC, time DESC, id DESC")
    suspend fun all(): List<ExpenseTransactionEntity>

    @Query("SELECT * FROM transactions WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): ExpenseTransactionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(transaction: ExpenseTransactionEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(transactions: List<ExpenseTransactionEntity>)

    @Delete
    suspend fun delete(transaction: ExpenseTransactionEntity)

    @Query("SELECT MAX(id) FROM transactions WHERE id LIKE :prefix || '%'")
    suspend fun maxIdForPrefix(prefix: String): Int?
}
```

Create `TransactionCategoryDao.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface TransactionCategoryDao {
    @Query("SELECT COUNT(*) FROM transaction_categories")
    suspend fun count(): Int

    @Query("SELECT * FROM transaction_categories ORDER BY transactionCategoryID ASC")
    suspend fun all(): List<TransactionCategoryEntity>

    @Query("SELECT * FROM transaction_categories WHERE type = :type ORDER BY transactionCategoryID ASC")
    suspend fun byType(type: String): List<TransactionCategoryEntity>

    @Query("SELECT * FROM transaction_categories WHERE transactionCategoryID = :id LIMIT 1")
    suspend fun byId(id: Int): TransactionCategoryEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(categories: List<TransactionCategoryEntity>)
}
```

- [ ] **Step 4: Create Room database**

Create `ExpenseTrackerDatabase.kt`:

```kotlin
package com.exptv2.app.expense

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [TransactionCategoryEntity::class, ExpenseTransactionEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class ExpenseTrackerDatabase : RoomDatabase() {
    abstract fun transactions(): ExpenseTransactionDao
    abstract fun categories(): TransactionCategoryDao

    companion object {
        @Volatile private var instance: ExpenseTrackerDatabase? = null

        fun get(context: Context): ExpenseTrackerDatabase {
            return instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    ExpenseTrackerDatabase::class.java,
                    "expense_tracker.db",
                ).build().also { instance = it }
            }
        }
    }
}
```

- [ ] **Step 5: Create exact seed data**

Create `ExpenseSeedData.kt` with these rows:

```kotlin
package com.exptv2.app.expense

object ExpenseSeedData {
    val categories = listOf(
        TransactionCategoryEntity(5, "Rr", "bevétel", 2, 0, "#3b82f6", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(6, "Q", "kiadás", 7, 2, "#dc2626", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(7, "Io", "kiadás", 2, 1, "#ef4444", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(8, "Gg", "kiadás", 1, 0, "#dc2626", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(9, "T", "kiadás", 3, 2, "#16a34a", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(10, "Hadfer", "kiadás", 17, 17, "#ef4444", "./assets/broccoli.png", null, true, 555.0, false, true, null),
        TransactionCategoryEntity(11, "U", "kiadás", 5, 0, "#b45309", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(12, "Ggz", "kiadás", 9, 0, "#22c55e", "./assets/broccoli.png", null, false, 0.0, false, true, null),
        TransactionCategoryEntity(13, "TestBroccoli", "kiadás", 4, 0, "#ea580c", "./assets/broccoli.png", null, false, 0.0, false, true, null),
    )

    val transactions = listOf(
        ExpenseTransactionEntity(250901, "2025.09.24", "20:31", null, null, "Unknown location", "Tt", -66.0, null, 9),
        ExpenseTransactionEntity(250902, "2025.09.24", "20:51", null, null, "Unknown location", "Ttqq", -22.0, null, 6),
        ExpenseTransactionEntity(250903, "2025.09.24", "21:14", null, null, "Unknown location", "Tt", -65.0, null, 9),
        ExpenseTransactionEntity(250904, "2025.09.24", "21:18", null, null, "Unknown location", "Uu", -55.0, null, 10),
        ExpenseTransactionEntity(250905, "2025.09.24", "21:56", null, null, "Unknown location", "Rrteeaawwq", 5555.0, "Gguu", 5),
        ExpenseTransactionEntity(250906, "2025.09.24", "22:39", null, null, "Unknown location", "Errr", -6513.0, null, 7),
        ExpenseTransactionEntity(250907, "2025.09.25", "5:29", null, null, "Unknown location", "Zzz", -6555.0, "Rrr", 6),
        ExpenseTransactionEntity(250908, "2025.09.25", "5:29", null, null, "Unknown location", "Zzz", -6580.0, "Rrr", 6),
        ExpenseTransactionEntity(250909, "2025.09.25", "20:30:00", null, null, "Unknown location", "Test Store", -505.0, null, 6),
        ExpenseTransactionEntity(250910, "2025.09.26", "7:03", null, null, "Unknown location", "Ii", 55.0, "Ggzz", 5),
        ExpenseTransactionEntity(250911, "2025.09.26", "7:16", null, null, "Unknown location", "Gg", -55.0, null, 7),
        ExpenseTransactionEntity(250912, "2025.09.26", "8:00", null, null, "Unknown location", "Tt", -2.0, null, 13),
        ExpenseTransactionEntity(250913, "2025.09.26", "8:00", null, null, "Unknown location", "Gf", -2.0, null, 13),
    )
}
```

- [ ] **Step 6: Create repository**

Create `ExpenseRepository.kt`:

```kotlin
package com.exptv2.app.expense

import android.content.Context
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class ExpenseRepository(context: Context) {
    private val db = ExpenseTrackerDatabase.get(context)
    private val transactions = db.transactions()
    private val categories = db.categories()

    suspend fun bootstrap(): Map<String, Any?> {
        seedIfEmpty()
        val categoryRows = categories.all()
        val transactionRows = transactions.all()
        return mapOf(
            "categories" to categoryRows.map { it.toMap() },
            "transactions" to transactionRows.map { it.toMap() },
        )
    }

    suspend fun listCategories(type: String?): List<Map<String, Any?>> {
        seedIfEmpty()
        val rows = when (normalizeHungarianType(type)) {
            null -> categories.all()
            else -> categories.byType(normalizeHungarianType(type)!!)
        }
        return rows.map { it.toMap() }
    }

    suspend fun listTransactions(args: Map<*, *>): List<Map<String, Any?>> {
        seedIfEmpty()
        val type = args["type"]?.toString()
        val searchQuery = args["searchQuery"]?.toString()?.trim().orEmpty()
        val merchant = args["merchant"]?.toString()?.trim().orEmpty()
        val categoryId = (args["categoryId"] as? Number)?.toInt()
        val yearMonth = args["yearMonth"]?.toString()?.trim().orEmpty()
        return transactions.all()
            .asSequence()
            .filter { row -> type == null || typeFromAmount(row.amount) == type }
            .filter { row -> categoryId == null || row.transactionCategoryID == categoryId }
            .filter { row -> merchant.isEmpty() || displayMerchant(row).equals(merchant, ignoreCase = false) }
            .filter { row -> searchQuery.isEmpty() || displayMerchant(row).contains(searchQuery, ignoreCase = true) }
            .filter { row -> yearMonth.isEmpty() || row.date.replace('.', '-').startsWith(yearMonth) }
            .map { it.toMap() }
            .toList()
    }

    suspend fun addTransaction(args: Map<*, *>): Map<String, Any?> {
        seedIfEmpty()
        val merchant = args["merchant"]?.toString()?.trim().orEmpty()
        if (merchant.isEmpty()) throw ExpenseValidationException("INVALID_TRANSACTION_NAME", "Transaction name is required")
        val rawAmount = (args["amount"] as? Number)?.toDouble()
            ?: args["amount"]?.toString()?.toDoubleOrNull()
            ?: throw ExpenseValidationException("INVALID_AMOUNT", "Amount must be numeric")
        if (rawAmount <= 0.0) throw ExpenseValidationException("INVALID_AMOUNT", "Amount must be greater than zero")
        val type = args["type"]?.toString() ?: "expense"
        if (type != "income" && type != "expense") throw ExpenseValidationException("INVALID_TRANSACTION_TYPE", "Type must be income or expense")
        val categoryId = (args["transactionCategoryID"] as? Number)?.toInt()
            ?: args["transactionCategoryID"]?.toString()?.toIntOrNull()
            ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category is required")
        categories.byId(categoryId) ?: throw ExpenseValidationException("INVALID_CATEGORY", "Category does not exist")

        val date = formatDate(args["date"]?.toString())
        val time = args["time"]?.toString()?.trim().takeUnless { it.isNullOrEmpty() } ?: "00:00"
        val signedAmount = if (type == "income") kotlin.math.abs(rawAmount) else -kotlin.math.abs(rawAmount)
        val row = ExpenseTransactionEntity(
            id = nextId(date),
            date = date,
            time = time,
            latitude = (args["latitude"] as? Number)?.toDouble(),
            longitude = (args["longitude"] as? Number)?.toDouble(),
            address = args["address"]?.toString() ?: "Unknown location",
            merchant = merchant,
            amount = signedAmount,
            userAssignedName = args["userAssignedName"]?.toString(),
            transactionCategoryID = categoryId,
        )
        transactions.insert(row)
        return row.toMap()
    }

    suspend fun deleteTransaction(id: Int): Boolean {
        seedIfEmpty()
        val row = transactions.byId(id) ?: return false
        transactions.delete(row)
        return true
    }

    private suspend fun seedIfEmpty() {
        if (categories.count() == 0) categories.insertAll(ExpenseSeedData.categories)
        if (transactions.count() == 0) transactions.insertAll(ExpenseSeedData.transactions)
    }

    private suspend fun nextId(date: String): Int {
        val compact = date.replace(".", "-")
        val parts = compact.split("-")
        val prefix = parts[0].takeLast(2) + parts[1].padStart(2, '0')
        val max = transactions.maxIdForPrefix(prefix)
        return if (max == null) "${prefix}01".toInt() else max + 1
    }

    private fun typeFromAmount(amount: Double): String = if (amount > 0) "income" else "expense"
    private fun displayMerchant(row: ExpenseTransactionEntity): String = row.userAssignedName?.takeIf { it.isNotBlank() } ?: row.merchant

    private fun normalizeHungarianType(type: String?): String? = when (type) {
        null, "" -> null
        "income", "bevétel" -> "bevétel"
        "expense", "kiadás" -> "kiadás"
        else -> null
    }

    private fun formatDate(value: String?): String {
        val input = value?.trim().takeUnless { it.isNullOrEmpty() } ?: LocalDate.now().toString()
        return input.replace('/', '-').replace('.', '-').let { normalized ->
            val date = LocalDate.parse(normalized, DateTimeFormatter.ISO_LOCAL_DATE)
            "%04d.%02d.%02d".format(date.year, date.monthValue, date.dayOfMonth)
        }
    }
}

class ExpenseValidationException(val code: String, message: String) : IllegalArgumentException(message)
```

- [ ] **Step 7: Compile Kotlin and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:kspDebugKotlin :app:compileDebugKotlin'
```

Expected: `BUILD SUCCESSFUL`.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense
git commit -m "feat: add expense room database"
```

---

### Task 3: Native Expense MethodChannel

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Modify: `lib/services/native_bridge.dart`
- Create: `test/transactions/native_bridge_expense_test.dart`

- [ ] **Step 1: Write failing Dart bridge tests**

Create `test/transactions/native_bridge_expense_test.dart`:

```dart
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/expense_methods');
  late NativeBridge bridge;

  setUp(() {
    bridge = NativeBridge(methodChannel: channel, eventChannel: const EventChannel('test/events'));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'expenseLoadBootstrap') {
        return {
          'categories': [
            {'transactionCategoryID': 5, 'name': 'Rr', 'type': 'bevétel', 'colorSlot': 2, 'iconSlot': 0, 'backgroundColor': '#3b82f6', 'hasLimit': false, 'limitAmount': 0, 'alertActive': false, 'isCustomIcon': true},
          ],
          'transactions': [
            {'id': 250905, 'date': '2025.09.24', 'time': '21:56', 'merchant': 'Rrteeaawwq', 'amount': 5555, 'userAssignedName': 'Gguu', 'transactionCategoryID': 5},
          ],
        };
      }
      if (call.method == 'expenseAddTransaction') {
        return {'id': 250914, 'date': '2025.09.26', 'time': '09:15', 'merchant': 'Salary', 'amount': 1000, 'userAssignedName': null, 'transactionCategoryID': 5};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('loads expense bootstrap payload', () async {
    final payload = await bridge.expenseLoadBootstrap();
    expect(payload.categories.single, isA<TransactionCategory>());
    expect(payload.transactions.single, isA<TransactionRecord>());
  });

  test('adds transaction through native bridge', () async {
    final record = await bridge.expenseAddTransaction({
      'merchant': 'Salary',
      'amount': 1000,
      'type': 'income',
      'transactionCategoryID': 5,
      'date': '2025-09-26',
      'time': '09:15',
    });
    expect(record.id, 250914);
    expect(record.amount, 1000);
  });
}
```

- [ ] **Step 2: Run bridge test and verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/native_bridge_expense_test.dart'
```

Expected: FAIL because expense bridge methods do not exist.

- [ ] **Step 3: Extend NativeBridge**

Modify `lib/services/native_bridge.dart` imports:

```dart
import '../features/transactions/models/transaction_category.dart';
import '../features/transactions/models/transaction_record.dart';
```

Add these classes and methods after existing fields:

```dart
class ExpenseBootstrapPayload {
  const ExpenseBootstrapPayload({required this.categories, required this.transactions});

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
}
```

Add methods inside `NativeBridge`:

```dart
  Future<ExpenseBootstrapPayload> expenseLoadBootstrap() async {
    final map = await _methodChannel.invokeMapMethod<dynamic, dynamic>('expenseLoadBootstrap');
    final payload = map ?? <dynamic, dynamic>{};
    final categories = (payload['categories'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(TransactionCategory.fromMap)
        .toList();
    final transactions = (payload['transactions'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(TransactionRecord.fromMap)
        .toList();
    return ExpenseBootstrapPayload(categories: categories, transactions: transactions);
  }

  Future<List<TransactionRecord>> expenseListTransactions(Map<String, Object?> filter) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>('expenseListTransactions', filter);
    return (rows ?? <dynamic>[]).cast<Map<dynamic, dynamic>>().map(TransactionRecord.fromMap).toList();
  }

  Future<List<TransactionCategory>> expenseListCategories({String? type}) async {
    final rows = await _methodChannel.invokeListMethod<dynamic>('expenseListCategories', {'type': type});
    return (rows ?? <dynamic>[]).cast<Map<dynamic, dynamic>>().map(TransactionCategory.fromMap).toList();
  }

  Future<TransactionRecord> expenseAddTransaction(Map<String, Object?> payload) async {
    final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>('expenseAddTransaction', payload);
    return TransactionRecord.fromMap(row ?? <dynamic, dynamic>{});
  }

  Future<bool> expenseDeleteTransaction(int id) async {
    final deleted = await _methodChannel.invokeMethod<bool>('expenseDeleteTransaction', {'id': id});
    return deleted ?? false;
  }
```

- [ ] **Step 4: Implement Kotlin channel handler**

Create `ExpenseMethodChannel.kt`:

```kotlin
package com.exptv2.app.expense

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ExpenseMethodChannel(
    context: Context,
    private val scope: CoroutineScope,
) {
    private val repository = ExpenseRepository(context)

    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "expenseLoadBootstrap" -> scope.launchResult(result) { repository.bootstrap() }
            "expenseListTransactions" -> scope.launchResult(result) { repository.listTransactions(call.argumentsMap()) }
            "expenseListCategories" -> scope.launchResult(result) {
                repository.listCategories(call.argumentsMap()["type"]?.toString())
            }
            "expenseAddTransaction" -> scope.launchResult(result) { repository.addTransaction(call.argumentsMap()) }
            "expenseDeleteTransaction" -> scope.launchResult(result) {
                val id = (call.argumentsMap()["id"] as? Number)?.toInt()
                    ?: throw ExpenseValidationException("INVALID_TRANSACTION_ID", "Transaction id is required")
                repository.deleteTransaction(id)
            }
            else -> return false
        }
        return true
    }

    private fun MethodCall.argumentsMap(): Map<*, *> = arguments as? Map<*, *> ?: emptyMap<String, Any?>()

    private fun CoroutineScope.launchResult(result: MethodChannel.Result, block: suspend () -> Any?) {
        launch {
            try {
                val payload = withContext(Dispatchers.IO) { block() }
                result.success(payload)
            } catch (error: ExpenseValidationException) {
                result.error(error.code, error.message, null)
            } catch (error: Exception) {
                result.error("EXPENSE_DB_ERROR", error.message, null)
            }
        }
    }
}
```

- [ ] **Step 5: Register channel in MainActivity**

Modify `MainActivity.configureFlutterEngine` before `MethodChannel(...).setMethodCallHandler`:

```kotlin
        val expenseChannel = ExpenseMethodChannel(this, scope)
```

Modify the `else -> result.notImplemented()` branch inside the existing MethodChannel handler:

```kotlin
                    else -> {
                        if (!expenseChannel.handle(call, result)) {
                            result.notImplemented()
                        }
                    }
```

- [ ] **Step 6: Run tests and compile Kotlin**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/native_bridge_expense_test.dart'
```

Expected: PASS.

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:kspDebugKotlin :app:compileDebugKotlin'
```

Expected: `BUILD SUCCESSFUL`.

Commit:

```bash
git add android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt lib/services/native_bridge.dart test/transactions/native_bridge_expense_test.dart
git commit -m "feat: expose expense native bridge"
```

---

### Task 4: Transaction Repository And Store

**Files:**
- Create: `lib/features/transactions/data/transaction_filter.dart`
- Create: `lib/features/transactions/data/transaction_repository.dart`
- Create: `lib/features/transactions/state/transaction_store.dart`
- Create: `test/transactions/transaction_store_test.dart`

- [ ] **Step 1: Write failing store tests**

Create `test/transactions/transaction_store_test.dart`:

```dart
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store loads bootstrap and filters by active type', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    expect(store.visibleTransactions.length, 2);
    store.setActiveType(TransactionType.income);
    expect(store.visibleTransactions.single.displayMerchant, 'Gguu');
    expect(store.activeSummary.formattedFor(TransactionType.income), '+5 555 Ft');
  });

  test('store applies merchant fast filter and search query', () async {
    final store = TransactionStore(FakeTransactionRepository());
    await store.start();

    store.setMerchantFilter('Rrr');
    expect(store.visibleTransactions.length, 2);

    store.clearMerchantFilter();
    store.setSearchQuery('test');
    expect(store.visibleTransactions.single.displayMerchant, 'Test Store');
  });

  test('store saves transaction then reloads bootstrap', () async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    await store.start();

    await store.addTransaction(
      merchant: 'New Shop',
      amount: 42,
      type: TransactionType.expense,
      categoryId: 6,
      date: '2025-09-26',
      time: '10:00',
    );

    expect(repository.savedPayloads.single['merchant'], 'New Shop');
    expect(store.visibleTransactions.first.displayMerchant, 'New Shop');
  });
}

class FakeTransactionRepository implements TransactionRepositoryContract {
  final savedPayloads = <Map<String, Object?>>[];
  final categories = <TransactionCategory>[
    TransactionCategory.fromMap({'transactionCategoryID': 5, 'name': 'Rr', 'type': 'bevétel', 'colorSlot': 2, 'iconSlot': 0, 'backgroundColor': '#3b82f6', 'hasLimit': false, 'limitAmount': 0, 'alertActive': false, 'isCustomIcon': true}),
    TransactionCategory.fromMap({'transactionCategoryID': 6, 'name': 'Q', 'type': 'kiadás', 'colorSlot': 7, 'iconSlot': 2, 'backgroundColor': '#dc2626', 'hasLimit': false, 'limitAmount': 0, 'alertActive': false, 'isCustomIcon': true}),
  ];
  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({'id': 250909, 'date': '2025.09.25', 'time': '20:30:00', 'merchant': 'Test Store', 'amount': -505, 'userAssignedName': null, 'transactionCategoryID': 6}),
    TransactionRecord.fromMap({'id': 250908, 'date': '2025.09.25', 'time': '5:29', 'merchant': 'Zzz', 'amount': -6580, 'userAssignedName': 'Rrr', 'transactionCategoryID': 6}),
    TransactionRecord.fromMap({'id': 250907, 'date': '2025.09.25', 'time': '5:29', 'merchant': 'Zzz', 'amount': -6555, 'userAssignedName': 'Rrr', 'transactionCategoryID': 6}),
    TransactionRecord.fromMap({'id': 250905, 'date': '2025.09.24', 'time': '21:56', 'merchant': 'Rrteeaawwq', 'amount': 5555, 'userAssignedName': 'Gguu', 'transactionCategoryID': 5}),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(categories: categories, transactions: transactions);

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) async {
    savedPayloads.add(payload);
    final record = TransactionRecord.fromMap({'id': 250914, 'date': '2025.09.26', 'time': '10:00', 'merchant': payload['merchant'], 'amount': -42, 'userAssignedName': null, 'transactionCategoryID': 6});
    transactions.insert(0, record);
    return record;
  }
}
```

- [ ] **Step 2: Run store test and verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_store_test.dart'
```

Expected: FAIL because repository and store files do not exist.

- [ ] **Step 3: Implement filter and repository**

Create `transaction_filter.dart`:

```dart
import '../models/transaction_category.dart';

class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionType.expense,
    this.searchQuery = '',
    this.merchant,
    this.categoryId,
  });

  final TransactionType type;
  final String searchQuery;
  final String? merchant;
  final int? categoryId;

  TransactionFilter copyWith({TransactionType? type, String? searchQuery, String? merchant, int? categoryId, bool clearMerchant = false}) {
    return TransactionFilter(
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
      merchant: clearMerchant ? null : merchant ?? this.merchant,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
```

Create `transaction_repository.dart`:

```dart
import '../../../services/native_bridge.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionBootstrap {
  const TransactionBootstrap({required this.categories, required this.transactions});

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
}

abstract class TransactionRepositoryContract {
  Future<TransactionBootstrap> loadBootstrap();
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload);
}

class TransactionRepository implements TransactionRepositoryContract {
  const TransactionRepository(this._bridge);

  final NativeBridge _bridge;

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    final payload = await _bridge.expenseLoadBootstrap();
    return TransactionBootstrap(categories: payload.categories, transactions: payload.transactions);
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    return _bridge.expenseAddTransaction(payload);
  }
}
```

- [ ] **Step 4: Implement store**

Create `transaction_store.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../data/transaction_filter.dart';
import '../data/transaction_repository.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import '../models/transaction_summary.dart';

enum SummaryWindow { monthly, yearly, allTime }

class TransactionStore extends ChangeNotifier {
  TransactionStore(this._repository);

  final TransactionRepositoryContract _repository;
  var _filter = const TransactionFilter();
  var _summaryWindow = SummaryWindow.monthly;
  var _loading = false;
  String? _error;
  List<TransactionCategory> _categories = [];
  List<TransactionRecord> _transactions = [];

  bool get loading => _loading;
  String? get error => _error;
  TransactionType get activeType => _filter.type;
  SummaryWindow get summaryWindow => _summaryWindow;
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  List<TransactionCategory> get activeCategories {
    return _categories.where((category) => category.normalizedType == _filter.type).toList();
  }

  List<TransactionRecord> get visibleTransactions {
    final query = _filter.searchQuery.trim().toLowerCase();
    final merchant = _filter.merchant?.trim();
    return _transactions.where((record) {
      if (record.type != _filter.type) return false;
      if (_filter.categoryId != null && record.transactionCategoryID != _filter.categoryId) return false;
      if (merchant != null && record.displayMerchant != merchant) return false;
      if (query.isNotEmpty && !record.displayMerchant.toLowerCase().contains(query)) return false;
      return true;
    }).toList();
  }

  TransactionSummary get activeSummary {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final source = _transactions.where((record) {
      if (record.type != _filter.type) return false;
      return switch (_summaryWindow) {
        SummaryWindow.monthly => record.yearMonthKey == month,
        SummaryWindow.yearly => record.yearMonthKey.startsWith(year),
        SummaryWindow.allTime => true,
      };
    });
    return TransactionSummary.fromRecords(source);
  }

  Future<void> start() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _repository.loadBootstrap();
      _categories = payload.categories;
      _transactions = _sort(payload.transactions);
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActiveType(TransactionType type) {
    _filter = _filter.copyWith(type: type, clearMerchant: true, searchQuery: '');
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _filter = _filter.copyWith(searchQuery: value);
    notifyListeners();
  }

  void setMerchantFilter(String merchant) {
    _filter = _filter.copyWith(merchant: merchant, searchQuery: '');
    notifyListeners();
  }

  void clearMerchantFilter() {
    _filter = _filter.copyWith(clearMerchant: true);
    notifyListeners();
  }

  void cycleSummaryWindow() {
    _summaryWindow = switch (_summaryWindow) {
      SummaryWindow.monthly => SummaryWindow.yearly,
      SummaryWindow.yearly => SummaryWindow.allTime,
      SummaryWindow.allTime => SummaryWindow.monthly,
    };
    notifyListeners();
  }

  Future<void> addTransaction({
    required String merchant,
    required double amount,
    required TransactionType type,
    required int categoryId,
    required String date,
    required String time,
  }) async {
    await _repository.addTransaction({
      'merchant': merchant,
      'amount': amount,
      'type': type.nativeValue,
      'transactionCategoryID': categoryId,
      'date': date,
      'time': time,
    });
    final payload = await _repository.loadBootstrap();
    _categories = payload.categories;
    _transactions = _sort(payload.transactions);
    notifyListeners();
  }

  List<TransactionRecord> _sort(List<TransactionRecord> records) {
    final rows = [...records];
    rows.sort((left, right) => right.id.compareTo(left.id));
    return rows;
  }
}
```

- [ ] **Step 5: Run store tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_store_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/data lib/features/transactions/state test/transactions/transaction_store_test.dart
git commit -m "feat: add transaction store"
```

---

### Task 5: Transaction Body Widgets

**Files:**
- Create: `test/transactions/transaction_widgets_test.dart`
- Create: `lib/features/transactions/widgets/transaction_type_pills.dart`
- Create: `lib/features/transactions/widgets/summary_pill.dart`
- Create: `lib/features/transactions/widgets/search_pill.dart`
- Create: `lib/features/transactions/widgets/transaction_log_box.dart`
- Create: `lib/features/transactions/widgets/transaction_log_list.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/transactions/transaction_widgets_test.dart`:

```dart
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/widgets/search_pill.dart';
import 'package:exptv2/features/transactions/widgets/summary_pill.dart';
import 'package:exptv2/features/transactions/widgets/transaction_log_box.dart';
import 'package:exptv2/features/transactions/widgets/transaction_type_pills.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('type pills switch active type', (tester) async {
    var selected = TransactionType.expense;
    await tester.pumpWidget(MaterialApp(home: TransactionTypePills(activeType: selected, onChanged: (type) => selected = type)));

    await tester.tap(find.text('Bevétel'));
    expect(selected, TransactionType.income);
  });

  testWidgets('summary pill cycles when dragged horizontally', (tester) async {
    var cycles = 0;
    await tester.pumpWidget(MaterialApp(home: SummaryPill(title: 'Kiadások', value: '-66 Ft', onSwipe: () => cycles += 1)));

    await tester.drag(find.byKey(const ValueKey('summary-pill')), const Offset(90, 0));
    await tester.pumpAndSettle();
    expect(cycles, 1);
  });

  testWidgets('search pill shows merchant filter capsule', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SearchPill(query: '', onQueryChanged: (_) {}, merchantFilter: 'Rrr', filteredCount: 2, onClearMerchant: () {})));

    expect(find.text('2 tranzakció találva'), findsOneWidget);
    expect(find.text('Rrr'), findsOneWidget);
  });

  testWidgets('logbox left swipe triggers fast filter', (tester) async {
    String? merchant;
    await tester.pumpWidget(MaterialApp(home: TransactionLogBox(record: sampleRecord(), category: sampleCategory(), onFastFilter: (value) => merchant = value)));

    await tester.drag(find.byKey(const ValueKey('transaction-logbox-250905')), const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(merchant, 'Gguu');
  });
}

TransactionRecord sampleRecord() => TransactionRecord.fromMap({'id': 250905, 'date': '2025.09.24', 'time': '21:56', 'merchant': 'Rrteeaawwq', 'amount': 5555, 'userAssignedName': 'Gguu', 'transactionCategoryID': 5});
TransactionCategory sampleCategory() => TransactionCategory.fromMap({'transactionCategoryID': 5, 'name': 'Rr', 'type': 'bevétel', 'colorSlot': 2, 'iconSlot': 0, 'backgroundColor': '#3b82f6', 'hasLimit': false, 'limitAmount': 0, 'alertActive': false, 'isCustomIcon': true});
```

- [ ] **Step 2: Run widget tests and verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_widgets_test.dart'
```

Expected: FAIL because widget files do not exist.

- [ ] **Step 3: Implement type pills**

Create `transaction_type_pills.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';

class TransactionTypePills extends StatelessWidget {
  const TransactionTypePills({super.key, required this.activeType, required this.onChanged});

  final TransactionType activeType;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(child: _Pill(type: TransactionType.income, active: activeType == TransactionType.income, onTap: onChanged)),
          const SizedBox(width: 10),
          Expanded(child: _Pill(type: TransactionType.expense, active: activeType == TransactionType.expense, onTap: onChanged)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.type, required this.active, required this.onTap});

  final TransactionType type;
  final bool active;
  final ValueChanged<TransactionType> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.white,
      elevation: active ? 3 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => onTap(type),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: active ? AppColors.primary : AppColors.gray200),
          ),
          child: Text(type.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: active ? AppColors.white : AppColors.gray500)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement summary and search pills**

Create `summary_pill.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SummaryPill extends StatelessWidget {
  const SummaryPill({super.key, required this.title, required this.value, required this.onSwipe});

  final String title;
  final String value;
  final VoidCallback onSwipe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('summary-pill'),
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0).abs() > 120) onSwipe();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 2), blurRadius: 3)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(title, style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.gray500))),
            Text(value, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w700, color: AppColors.gray800)),
          ],
        ),
      ),
    );
  }
}
```

Create `search_pill.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({super.key, required this.query, required this.onQueryChanged, required this.filteredCount, this.merchantFilter, this.onClearMerchant});

  final String query;
  final ValueChanged<String> onQueryChanged;
  final int filteredCount;
  final String? merchantFilter;
  final VoidCallback? onClearMerchant;

  @override
  Widget build(BuildContext context) {
    final hasMerchant = merchantFilter != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 2), blurRadius: 3)],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.gray400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: query)..selection = TextSelection.collapsed(offset: query.length),
              onChanged: onQueryChanged,
              decoration: InputDecoration(border: InputBorder.none, hintText: hasMerchant ? '$filteredCount tranzakció találva' : 'Keresés tranzakciók között...', isDense: true),
            ),
          ),
          if (hasMerchant)
            Container(
              height: 30,
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(merchantFilter!, style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: onClearMerchant, icon: const Icon(Icons.close, size: 14, color: AppColors.white), padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 28, height: 28)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Implement logbox and list**

Create `transaction_log_box.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class TransactionLogBox extends StatelessWidget {
  const TransactionLogBox({super.key, required this.record, required this.category, required this.onFastFilter});

  final TransactionRecord record;
  final TransactionCategory? category;
  final ValueChanged<String> onFastFilter;

  @override
  Widget build(BuildContext context) {
    final amountColor = record.type == TransactionType.income ? AppColors.income : AppColors.expense;
    return GestureDetector(
      key: ValueKey('transaction-logbox-${record.id}'),
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -200) onFastFilter(record.displayMerchant);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), offset: const Offset(0, 2), blurRadius: 3)],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: category?.slotColor ?? AppColors.gray500, shape: BoxShape.circle),
              child: const Icon(Icons.category, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(record.displayMerchant, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(record.displayAmount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: amountColor)),
                const SizedBox(height: 2),
                Text(record.displayTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

Create `transaction_log_list.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';
import 'transaction_log_box.dart';

class TransactionLogList extends StatelessWidget {
  const TransactionLogList({super.key, required this.records, required this.categories, required this.onFastFilter});

  final List<TransactionRecord> records;
  final List<TransactionCategory> categories;
  final ValueChanged<String> onFastFilter;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('Nincs megjeleníthető tranzakció', style: TextStyle(color: AppColors.gray500)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final category = categories.where((item) => item.transactionCategoryID == record.transactionCategoryID).firstOrNull;
        return TransactionLogBox(record: record, category: category, onFastFilter: onFastFilter);
      },
    );
  }
}
```

- [ ] **Step 6: Run widget tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/transaction_widgets_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets test/transactions/transaction_widgets_test.dart
git commit -m "feat: add transaction body widgets"
```

---

### Task 6: Add Transaction Sheet And Home Page

**Files:**
- Create: `lib/features/transactions/widgets/amount_field.dart`
- Create: `lib/features/transactions/widgets/category_selector_field.dart`
- Create: `lib/features/transactions/widgets/date_time_fields.dart`
- Create: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Create: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/main.dart`
- Modify: `lib/exptv2_app.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Update widget test for home and FAB**

Modify `test/widget_test.dart` first test to expect the transaction home instead of blank home:

```dart
expect(find.text('Kiadás'), findsOneWidget);
expect(find.text('Bevétel'), findsOneWidget);
expect(find.byKey(const ValueKey('expt-fab')), findsOneWidget);
```

Add a new test:

```dart
testWidgets('FAB opens add transaction sheet on home tab', (tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('expt-fab')));
  await tester.pumpAndSettle();

  expect(find.text('Új kiadási tranzakció'), findsOneWidget);
  expect(find.text('Tranzakció neve'), findsOneWidget);
  expect(find.text('Összeg'), findsOneWidget);
  expect(find.text('Kategória'), findsOneWidget);
});
```

Extend the mock method handler in `widget_test.dart`:

```dart
if (call.method == 'expenseLoadBootstrap') {
  return <String, Object?>{
    'categories': <Map<String, Object?>>[
      {'transactionCategoryID': 5, 'name': 'Rr', 'type': 'bevétel', 'colorSlot': 2, 'iconSlot': 0, 'backgroundColor': '#3b82f6', 'hasLimit': false, 'limitAmount': 0, 'alertActive': false, 'isCustomIcon': true},
      {'transactionCategoryID': 6, 'name': 'Q', 'type': 'kiadás', 'colorSlot': 7, 'iconSlot': 2, 'backgroundColor': '#dc2626', 'hasLimit': false, 'limitAmount': 0, 'alertActive': false, 'isCustomIcon': true},
    ],
    'transactions': <Map<String, Object?>>[
      {'id': 250909, 'date': '2025.09.25', 'time': '20:30:00', 'merchant': 'Test Store', 'amount': -505, 'userAssignedName': null, 'transactionCategoryID': 6},
    ],
  };
}
if (call.method == 'expenseAddTransaction') {
  return <String, Object?>{'id': 250914, 'date': '2025.09.26', 'time': '10:00', 'merchant': 'New Shop', 'amount': -42, 'userAssignedName': null, 'transactionCategoryID': 6};
}
```

- [ ] **Step 2: Run widget test and verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart'
```

Expected: FAIL because home still renders `BlankTabPage` and FAB has no transaction sheet.

- [ ] **Step 3: Implement form field widgets**

Create `amount_field.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AmountField extends StatelessWidget {
  const AmountField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Összeg',
        suffixText: 'Ft',
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
      ),
    );
  }
}
```

Create `category_selector_field.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';

class CategorySelectorField extends StatelessWidget {
  const CategorySelectorField({super.key, required this.categories, required this.selected, required this.onChanged});

  final List<TransactionCategory> categories;
  final TransactionCategory? selected;
  final ValueChanged<TransactionCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TransactionCategory>(
      value: selected,
      items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category.name))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Kategória',
        filled: true,
        fillColor: selected?.slotColor ?? AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
      ),
      selectedItemBuilder: (context) => categories.map((category) => Text(category.name, style: TextStyle(color: selected == category ? AppColors.white : AppColors.gray800))).toList(),
    );
  }
}
```

Create `date_time_fields.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DateTimeFields extends StatelessWidget {
  const DateTimeFields({super.key, required this.dateController, required this.timeController});

  final TextEditingController dateController;
  final TextEditingController timeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Field(label: 'Dátum', controller: dateController)),
        const SizedBox(width: 12),
        Expanded(child: _Field(label: 'Idő', controller: timeController)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement add transaction sheet**

Create `add_transaction_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/transaction_category.dart';
import '../state/transaction_store.dart';
import 'amount_field.dart';
import 'category_selector_field.dart';
import 'date_time_fields.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key, required this.store});

  final TransactionStore store;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  TransactionCategory? _category;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date.text = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _time.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.store.activeType;
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(type == TransactionType.income ? 'Új bevételi tranzakció' : 'Új kiadási tranzakció', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: _decor('Tranzakció neve')),
          const SizedBox(height: 12),
          AmountField(controller: _amount),
          const SizedBox(height: 12),
          CategorySelectorField(categories: widget.store.activeCategories, selected: _category, onChanged: (value) => setState(() => _category = value)),
          const SizedBox(height: 12),
          DateTimeFields(dateController: _date, timeController: _time),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: AppColors.expense))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, style: FilledButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Mentés')),
        ],
      ),
    );
  }

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.gray50,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: AppColors.gray200)),
  );

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim().replaceAll(' ', ''));
    if (_name.text.trim().isEmpty || amount == null || _category == null) {
      setState(() => _error = 'Hiányzó vagy hibás adat');
      return;
    }
    await widget.store.addTransaction(
      merchant: _name.text.trim(),
      amount: amount,
      type: widget.store.activeType,
      categoryId: _category!.transactionCategoryID,
      date: _date.text.trim(),
      time: _time.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }
}
```

- [ ] **Step 5: Implement transaction home page**

Create `transaction_home_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'state/transaction_store.dart';
import 'widgets/search_pill.dart';
import 'widgets/summary_pill.dart';
import 'widgets/transaction_log_list.dart';
import 'widgets/transaction_type_pills.dart';

class TransactionHomePage extends StatefulWidget {
  const TransactionHomePage({super.key, required this.store});

  final TransactionStore store;

  @override
  State<TransactionHomePage> createState() => _TransactionHomePageState();
}

class _TransactionHomePageState extends State<TransactionHomePage> {
  @override
  void initState() {
    super.initState();
    widget.store.start();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        if (widget.store.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        return Column(
          children: [
            const SizedBox(height: 185),
            TransactionTypePills(activeType: widget.store.activeType, onChanged: widget.store.setActiveType),
            SummaryPill(title: widget.store.activeType == TransactionType.income ? 'Bevételek' : 'Kiadások', value: widget.store.activeSummary.formattedFor(widget.store.activeType), onSwipe: widget.store.cycleSummaryWindow),
            SearchPill(query: '', onQueryChanged: widget.store.setSearchQuery, merchantFilter: null, filteredCount: widget.store.visibleTransactions.length, onClearMerchant: widget.store.clearMerchantFilter),
            Expanded(child: TransactionLogList(records: widget.store.visibleTransactions, categories: widget.store.categories, onFastFilter: widget.store.setMerchantFilter)),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 6: Wire shared NativeBridge and home FAB**

Modify `lib/main.dart`:

```dart
void main() {
  final bridge = NativeBridge();
  runApp(Exptv2App(store: EventStore(bridge), nativeBridge: bridge));
}
```

Modify `lib/exptv2_app.dart` constructor and fields:

```dart
  const Exptv2App({super.key, required this.store, required this.nativeBridge});

  final EventStore store;
  final NativeBridge nativeBridge;
```

Pass to shell:

```dart
home: ExptShell(store: store, nativeBridge: nativeBridge),
```

Modify `lib/features/shell/expt_shell.dart` imports:

```dart
import '../../services/native_bridge.dart';
import '../transactions/data/transaction_repository.dart';
import '../transactions/state/transaction_store.dart';
import '../transactions/transaction_home_page.dart';
import '../transactions/widgets/add_transaction_sheet.dart';
```

Add fields and init state:

```dart
  final NativeBridge nativeBridge;
```

Inside state:

```dart
  late final TransactionStore _transactionStore;

  @override
  void initState() {
    super.initState();
    _transactionStore = TransactionStore(TransactionRepository(widget.nativeBridge));
  }
```

Replace the home child:

```dart
TransactionHomePage(store: _transactionStore),
```

Replace FAB callback:

```dart
child: Center(child: ExptFab(onPressed: _handleFabPressed)),
```

Add method:

```dart
  void _handleFabPressed() {
    if (_activeTab != AppTab.home) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => AddTransactionSheet(store: _transactionStore),
    );
  }
```

Update `test/widget_test.dart` `buildApp()`:

```dart
  Widget buildApp() {
    final bridge = NativeBridge();
    return Exptv2App(store: EventStore(bridge, realtimeEnabled: false), nativeBridge: bridge);
  }
```

- [ ] **Step 7: Run shell tests and commit**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/main.dart lib/exptv2_app.dart lib/features/shell/expt_shell.dart lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/amount_field.dart lib/features/transactions/widgets/category_selector_field.dart lib/features/transactions/widgets/date_time_fields.dart lib/features/transactions/widgets/add_transaction_sheet.dart test/widget_test.dart
git commit -m "feat: add transaction home and form"
```

---

### Task 7: Full Verification And Cleanup

**Files:**
- Modify only files required by analyzer or failing tests.

- [ ] **Step 1: Run Flutter format**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/dart format lib test'
```

Expected: files are formatted without parse errors.

- [ ] **Step 2: Run Flutter analyze**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`.

- [ ] **Step 3: Run all Flutter tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all tests pass.

- [ ] **Step 4: Run Android Kotlin compile**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:kspDebugKotlin :app:compileDebugKotlin'
```

Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Commit verification fixes**

If formatter or analyzer changed files, commit them:

```bash
git add lib test android/app/src/main/kotlin
git commit -m "chore: polish transaction slice"
```

If no files changed, skip this commit.

---

### Task 8: Push And GitHub APK Build

**Files:**
- No source edits unless GitHub Actions reveals a build-specific failure.

- [ ] **Step 1: Push branch**

Run:

```bash
git push origin main
```

Expected: push succeeds to `https://github.com/elizerpist/exptv2.git`.

- [ ] **Step 2: Trigger online build**

The push triggers `.github/workflows/android-build.yml` automatically. If a manual dispatch is needed, run:

```bash
gh workflow run android-build.yml --repo elizerpist/exptv2
```

Expected: a new GitHub Actions run starts for `Exptv2 Android APK Build`.

- [ ] **Step 3: Check workflow result**

Run:

```bash
gh run list --repo elizerpist/exptv2 --workflow android-build.yml --limit 1
```

Expected: latest run eventually reaches `completed success`.

- [ ] **Step 4: Report artifact**

Run:

```bash
gh run view --repo elizerpist/exptv2 --log --job build-debug-apk
```

Expected: logs include `Upload debug APK` and artifact name `exptv2-debug-apk`.

Final report should include:

- latest commit hash
- GitHub Actions run URL
- APK artifact name: `exptv2-debug-apk`
- local verification commands and results

---

## Self-Review

Spec coverage:

- Kotlin Room DB, cloned schemas, seed data, MethodChannel read/write: Tasks 2 and 3.
- Flutter home body with type pills, summary, search, logboxes: Tasks 4 and 5.
- FAB add transaction menu and DB save/reload: Task 6.
- Colors and slot colors: Task 1.
- Bottom nav/settings preservation: Task 6 widget tests plus Task 7 full tests.
- GitHub build artifact: Task 8.

Type consistency:

- Native methods use `expenseLoadBootstrap`, `expenseListTransactions`, `expenseListCategories`, `expenseAddTransaction`, `expenseDeleteTransaction` consistently in Kotlin and Dart.
- Category IDs use `transactionCategoryID` consistently.
- Active type uses `TransactionType.income` / `TransactionType.expense` in Dart and `income` / `expense` over MethodChannel.
- Room keeps old category type strings `bevétel` / `kiadás` for seed compatibility.

Scope control:

- Push parser to transaction automation is out of scope for this plan.
- Icon assets are out of scope for this plan.
- Category management menus are out of scope for this plan.
- Right-swipe delete confirmation UI is out of scope for this plan, while the native delete method is available.
