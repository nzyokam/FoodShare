import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String selectedCity;
  final DateTime? selectedDate;
  final Function(String) onCityChanged;
  final Function(DateTime?) onDateChanged;

  const FilterBar({
    super.key,
    required this.selectedCity,
    required this.selectedDate,
    required this.onCityChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedCity.isNotEmpty ? selectedCity : null,
              hint: Text('City', style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
              items: ['Nairobi', 'Nakuru', 'Mombasa', 'Other']
                  .map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city,),
                      ))
                  .toList(),
              onChanged: (value) => onCityChanged(value ?? ''),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                onDateChanged(picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Date',
                ),
                child: Text(
                  selectedDate != null
                      ? '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'
                      : 'Pick Date',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
